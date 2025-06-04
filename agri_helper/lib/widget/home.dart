import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:agri_helper/appconstant.dart';
import 'package:agri_helper/benh_lua.dart';
import 'package:agri_helper/provider/user_provider.dart';
import 'package:agri_helper/widget/ImagePickerWidget.dart';
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
  Home({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _HomeState();
  }
}

class _HomeState extends ConsumerState<Home> {
  String username = '';
  File? _imagePick;
  String content = '';
  bool isLoading = false;

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
  String get selectedFruit => plantTypeMap[selectedFruitDisplay] ?? 'rice'; // For API

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

  void _submitImage() async {
    if (_imagePick == null) return;

    setState(() => isLoading = true);

    final uri = Uri.parse(apilua);
    final request = http.MultipartRequest('POST', uri);
    request.fields['fruit'] = selectedFruit;
    request.files.add(
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
        String diseaseName = '';
        if (pd is List && pd.isNotEmpty) {
          diseaseName = pd[0].toString();
        }
        setState(() {
          content = diseaseName;
          isLoading = false;
        });
      } else {
        setState(() {
          content = 'error: HTTP ${response.statusCode}';
          isLoading = false;
        });
      }
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
                    spreadRadius: 0,
                  ),
                ],
              ),
              padding: EdgeInsets.all(16),
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
                  SizedBox(height: 12),
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
                      padding: EdgeInsets.symmetric(horizontal: 16),
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
                      icon: Icon(Icons.keyboard_arrow_down_rounded, size: 28),
                      iconEnabledColor: Colors.teal,
                    ),
                    menuItemStyleData: MenuItemStyleData(
                      height: 45,
                      padding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onChanged: (value) {
                      if (value != null) setState(() => selectedFruitDisplay = value);
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
                    spreadRadius: 0,
                  ),
                ],
              ),
              padding: EdgeInsets.all(20),
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
                  SizedBox(height: 16),
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
                    padding: EdgeInsets.all(16),
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

                  SizedBox(height: 20),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.science_outlined),
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
                        padding: EdgeInsets.symmetric(vertical: 16),
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
                margin: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Column(
                    children: [
                      SpinKitWave(
                        color: Colors.teal[700]!,
                        size: 40.0,
                      ),
                      SizedBox(height: 16),
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
                margin: EdgeInsets.only(top: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kết quả phân tích',
                      style: GoogleFonts.roboto(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.teal[800],
                      ),
                    ),
                    SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: content == 'healthy'
                            ? Colors.green.shade50
                            : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: content == 'healthy'
                              ? Colors.green.shade200
                              : Colors.orange.shade200,
                        ),
                      ),
                      child: Text(
                        'Kết quả: ${info[content]?["name"] ?? content}',
                        style: GoogleFonts.roboto(
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          color: content == 'healthy'
                              ? Colors.green.shade700
                              : Colors.orange.shade900,
                        ),
                      ),
                    ),
                    if (info[content]?['info'] != null) ...[
                      SizedBox(height: 16),
                      Container(
                        padding: EdgeInsets.all(16),
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
                            SizedBox(height: 8),
                            Text(
                              info[content]!['info']!,
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
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
