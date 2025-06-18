// lib/widget/home.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/services.dart' show rootBundle;

import 'package:agri_helper/appconstant.dart';
import 'package:agri_helper/benh_lua.dart';
import 'package:agri_helper/provider/user_provider.dart';
import 'package:agri_helper/widget/imagepickerwidget.dart';
import 'package:agri_helper/widget/userinfo.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:lottie/lottie.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

class Home extends ConsumerStatefulWidget {
  const Home({super.key});

  @override
  ConsumerState<Home> createState() => _HomeState();
}

class _HomeState extends ConsumerState<Home> {
  String username = '';
  File? _imagePick;
  String content = '';
  bool isLoading = false;
  final List<(String, double)> predictions = [];

  // Plant type mapping Vietnamese - English
  final Map<String, String> plantTypeMap = {
    'Cây lúa': 'rice',
    'Táo': 'apple',
    'Dâu tây': 'strawberry',
    'Khoai tây': 'potato',
    'Sầu riêng': 'durian',
    'Xoài': 'mango',
    'Ngô': 'corn',
    'Chuối': 'banana',
    'Nho': 'grape',
    'Ớt': 'pepper',
    'Cà chua': 'tomato',
    'Cam': 'orange',
    'Đào': 'peach'
  };

  String selectedFruitDisplay = 'Cây lúa'; // For display
  String get selectedFruit =>
      plantTypeMap[selectedFruitDisplay] ?? 'rice'; // For API

  @override
  void initState() {
    super.initState();
    final name = ref.read(UserProvider);
    if (name["username"] != "") {
      username = name["username"]!;
      return;
    }

    FirebaseFirestore.instance
        .collection("users")
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get()
        .then((value) {
          final data = value.data();
          setState(() {
            username = data == null ? 'Không xác định' : data['username'];
          });
          if (data != null) {
            ref.read(UserProvider.notifier).setUsername(data['username']);
            ref.read(UserProvider.notifier).setphone(data['phone']);
          }
        });
  }

  Future<void> _submitImage() async {
    if (_imagePick == null) return;

    setState(() {
      isLoading = true;
      predictions.clear();
    });

    final uri = Uri.parse(apilua);
    final request = http.MultipartRequest('POST', uri)
      ..fields['fruit'] = selectedFruit
      ..files.add(
        await http.MultipartFile.fromPath(
          'file',
          _imagePick!.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

    try {
      final streamed = await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonMap = json.decode(response.body);
        final dynamic pd = jsonMap['predicted_disease'];
          setState(() {
          if (pd is List && pd.isNotEmpty) {
            if (pd[0].toString() == "no") {
              content = "Ảnh không hợp lệ";
            } else {
              // Get main prediction
              final mainDisease = pd[0].toString();
              final mainProbability = pd[1] as num;
              content = mainDisease;
              predictions.add((mainDisease, mainProbability.toDouble()));

              // Get other probabilities
              final Map<String, dynamic> probabilities = jsonMap['probabilities'];
              probabilities.forEach((disease, probability) {
                if (disease != mainDisease) {
                  predictions.add((disease, (probability as num).toDouble()));
                }
              });
              
              // Sort other predictions by percentage in descending order
              predictions.sort((a, b) => b.$2.compareTo(a.$2));
            }
          }
          isLoading = false;
        });

        // Get disease images for the main prediction
        _getDiseaseImages(predictions.first.$1).then((images) {
          setState(() {
            diseaseImages = images;
          });
        });
      } else {
        setState(() {
          content = 'error: HTTP ${response.statusCode}';
          isLoading = false;
        });
      }
    } on SocketException {
      setState(() {
        content = "Kiểm tra lại đường truyền mạng của bạn!";
        isLoading = false;
      });
    } on TimeoutException {
      setState(() {
        content = 'error: timeout';
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        content = 'error: $e';
        isLoading = false;
      });
    }
  }
  Widget _buildPredictionItem(String diseaseName, double percentage, bool isMain) {
    final displayName = info.containsKey(diseaseName) 
        ? info[diseaseName]!["name"].toString() 
        : diseaseName;
    
    return Container(
      padding: EdgeInsets.all(isMain ? 12 : 8),
      margin: isMain ? null : const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isMain ? Colors.teal.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              displayName,
              style: GoogleFonts.roboto(
                fontSize: isMain ? 17 : 15,
                fontWeight: isMain ? FontWeight.w500 : FontWeight.normal,
                color: isMain ? Colors.orange.shade900 : Colors.black87,
              ),
            ),
          ),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: GoogleFonts.roboto(
              fontSize: isMain ? 17 : 15,
              fontWeight: isMain ? FontWeight.w500 : FontWeight.normal,
              color: isMain ? Colors.teal[800] : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  // Get random disease images based on plant type and disease name
  Future<List<String>> _getRandomDiseaseImages(String plantType, String diseaseName) async {
    if (diseaseName.toLowerCase().contains('healthy') || 
        diseaseName.toLowerCase() == 'no') {
      return [];
    }

    try {
      String plantFolder = plantType.toLowerCase();
      String diseaseFolder = diseaseName;
      String basePath = 'assets/disease/$plantFolder/$diseaseFolder';
      
      // Get all available images in the folder by trying common image patterns
      List<String> allImages = [];
      final assetManifest = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(assetManifest);
      
      // Filter assets to get only images from our disease folder
      allImages = manifestMap.keys
          .where((String key) => key.startsWith(basePath) && 
                               (key.endsWith('.jpg') || 
                                key.endsWith('.jpeg') || 
                                key.endsWith('.png')))
          .toList();

      if (allImages.isEmpty) return [];

      // Shuffle and take up to 3 images
      allImages.shuffle(math.Random());
      return allImages.take(3).toList();
    } catch (e) {
      print('Error getting disease images: $e');
      return [];
    }
  }

  // Lấy danh sách 3 ảnh minh họa ngẫu nhiên cho bệnh
  Future<List<String>> _getDiseaseImages(String diseaseName) async {
    try {
      // Load manifest file để lấy danh sách assets
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);
      
      // Lấy tất cả các assets trong thư mục bệnh tương ứng
      final diseasePath = 'assets/disease/${selectedFruit}/$diseaseName';
      final imageAssets = manifestMap.keys
          .where((String key) => key.startsWith(diseasePath) && 
              (key.endsWith('.jpg') || key.endsWith('.png') || key.endsWith('.jpeg')))
          .toList();

      if (imageAssets.isEmpty) {
        return [];
      }

      // Chọn ngẫu nhiên 3 ảnh hoặc ít hơn nếu không đủ
      imageAssets.shuffle();
      return imageAssets.take(3).toList();
    } catch (e) {
      print('Error loading disease images: $e');
      return [];
    }
  }

  List<String> diseaseImages = [];

  Widget _buildDiseaseImages() {
    if (diseaseImages.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hình ảnh minh họa:',
            style: GoogleFonts.roboto(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: diseaseImages.map((imagePath) {
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultContent() {
    if (content == "Ảnh không hợp lệ" || predictions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          content,
          textAlign: TextAlign.center,
          style: GoogleFonts.roboto(
            fontSize: 17,
            fontWeight: FontWeight.w500,
            color: Colors.redAccent,
          ),
        ),
      );
    }
    
    return FutureBuilder<List<String>>(
      future: _getRandomDiseaseImages(selectedFruit, predictions.first.$1),
      builder: (context, snapshot) {
        final List<Widget> children = [
          Text(
            'Kết quả chẩn đoán chính:',
            style: GoogleFonts.roboto(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.teal[800],
            ),
          ),
          const SizedBox(height: 8),
            // Main prediction
          _buildPredictionItem(predictions.first.$1, predictions.first.$2, true),
          
          // Other diseases with non-zero probability
          if (predictions.length > 1) ...[
            const SizedBox(height: 16),
            Text(
              'Các bệnh khác có thể xảy ra:',
              style: GoogleFonts.roboto(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.teal[800],
              ),
            ),
            const SizedBox(height: 8),
            ...predictions
                .skip(1)
                .where((pred) => pred.$2 > 0)
                .take(3)
                .map((pred) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: _buildPredictionItem(pred.$1, pred.$2, false),
                    )),
          ],
          
          // Disease details
          if (info.containsKey(predictions.first.$1) &&
              info[predictions.first.$1]?['info'] != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Thông tin chi tiết:',
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.teal[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    info[predictions.first.$1]!['info'].toString(),
                    style: GoogleFonts.roboto(
                      fontSize: 15,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info
            UserInfoCard(username: username),
            const SizedBox(height: 24),

            // Plant Type Selection Section
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chọn loại cây:',
                    style: GoogleFonts.roboto(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.teal[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButton2<String>(
                    isExpanded: true,
                    value: selectedFruitDisplay,
                    items: plantTypeMap.keys
                        .map((name) => DropdownMenuItem(
                              value: name,
                              child: Text(
                                name,
                                style: GoogleFonts.roboto(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                            ))
                        .toList(),
                    buttonStyleData: ButtonStyleData(
                      height: 50,
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.teal.shade100),
                        color: Colors.white,
                      ),
                    ),
                    dropdownStyleData: DropdownStyleData(
                      maxHeight: 300,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white,
                      ),
                    ),
                    iconStyleData: IconStyleData(
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 28),
                      iconEnabledColor: Colors.teal,
                    ),
                    menuItemStyleData: const MenuItemStyleData(
                      height: 45,
                      padding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedFruitDisplay = value);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Disease Diagnosis Section
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chẩn đoán bệnh',
                    style: GoogleFonts.roboto(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: Colors.teal[800],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Image picker
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.teal.shade50,
                        width: 1,
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () async {
                            final img = await showModalBottomSheet<File>(
                              context: context,
                              builder: (ctx) => ImagePickerWidget(
                                onPickImage: (img) {
                                  Navigator.of(ctx).pop(img);
                                },
                              ),
                            );
                            if (img != null) {
                              setState(() => _imagePick = img);
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            height: 200,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.white,
                            ),
                            child: _imagePick == null
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Lottie.asset(
                                        'assets/lottie/upload.json',
                                        width: 150,
                                        repeat: true,
                                      ),
                                      Text(
                                        "Nhấn để chọn ảnh cây cần kiểm tra",
                                        style: GoogleFonts.roboto(
                                          color: Colors.grey[700],
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  )
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(
                                      _imagePick!,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.science_outlined),
                      label: Text(
                        'Bắt đầu phân tích',
                        style: GoogleFonts.roboto(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 1,
                      ),
                      onPressed: isLoading ? null : _submitImage,
                    ),
                  ),
                ],
              ),
            ),

            // Loading indicator
            if (isLoading)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Column(
                    children: [
                      SpinKitWave(
                        color: Colors.teal[700]!,
                        size: 40.0,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Đang phân tích...',
                        style: GoogleFonts.roboto(
                          color: Colors.teal[700],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Result section
            if (content.isNotEmpty && !isLoading)
              Container(
                margin: const EdgeInsets.only(top: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: _buildResultContent(),
              ),

            // Display disease illustrations
            if (!isLoading && predictions.isNotEmpty && predictions.first.$1 != "no")
              _buildDiseaseImages(),
          ],
        ),
      ),
    );
  }
}
