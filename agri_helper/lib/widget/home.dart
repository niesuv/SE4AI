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

  final List<String> fruitTypes = [
    'apple', 'strawberry', 'rice', 'potato', 'durian', 'mango',
    'corn', 'banana', 'grape', 'pepper', 'tomato', 'mango_Fruit', 'orange', 'peach'
  ];
  String selectedFruit = 'rice';

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
            const SizedBox(height: 18),

            // Fruit Dropdown
            Text('Chọn loại cây:',
                style: GoogleFonts.roboto(
                    fontSize: 17, fontWeight: FontWeight.w500, color: Colors.black87)),
            const SizedBox(height: 8),
            DropdownButton2<String>(
              isExpanded: true,
              value: selectedFruit,
              items: fruitTypes
                  .map((fruit) => DropdownMenuItem(
                        value: fruit,
                        child: Text(
                          fruit,
                          style: GoogleFonts.poppins(fontSize: 16),
                        ),
                      ))
                  .toList(),
              buttonStyleData: ButtonStyleData(
                height: 48,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white,
                  border: Border.all(color: Colors.blueGrey.shade100, width: 1),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.blueGrey.withOpacity(0.08),
                        blurRadius: 5,
                        offset: Offset(0, 3))
                  ],
                ),
              ),
              dropdownStyleData: DropdownStyleData(
                maxHeight: 350,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: Colors.white,
                ),
              ),
              iconStyleData: IconStyleData(
                icon: Icon(Icons.arrow_drop_down_rounded, size: 28),
              ),
              onChanged: (value) {
                if (value != null) setState(() => selectedFruit = value);
              },
            ),
            const SizedBox(height: 22),

            // Title
            Text('Chẩn đoán bệnh lúa',
                style: GoogleFonts.roboto(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: Colors.teal[800])),
            const SizedBox(height: 10),

            // Image picker
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8),
                child: Column(
                  children: [
                    _imagePick == null
                        ? Column(
                            children: [
                              Lottie.asset('assets/lottie/upload.json', width: 120, repeat: true),
                              Text("Vui lòng chọn ảnh cây cần kiểm tra",
                                  style: GoogleFonts.roboto(color: Colors.grey[700])),
                            ],
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.file(_imagePick!, height: 140, fit: BoxFit.cover),
                          ),
                    ImagePickerWidget(
                      onPickImage: (img) {
                        setState(() => _imagePick = img);
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Submit button
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: Icon(Icons.science_outlined),
                label: Text('Bắt đầu phân tích',
                    style: GoogleFonts.roboto(fontSize: 19, fontWeight: FontWeight.w500)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                onPressed: isLoading ? null : _submitImage,
              ),
            ),

            // Loading
            if (isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 18.0),
                child: Center(
                  child: SpinKitWave(
                    color: Colors.teal[700]!,
                    size: 40.0,
                  ),
                ),
              ),

            // Result
            if (content.isNotEmpty && !isLoading)
              Card(
                elevation: 3,
                margin: const EdgeInsets.only(top: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: content == 'healthy'
                                ? const Color.fromARGB(255, 32, 209, 65)
                                : Colors.amber,
                            foregroundColor: content == 'healthy'
                                ? Colors.white
                                : const Color.fromARGB(255, 194, 41, 27),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 1,
                          ),
                          onPressed: () {},
                          child: Text(
                            'Kết quả: ${info[content]?["name"] ?? content}',
                            style: GoogleFonts.roboto(
                                fontSize: 18, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                      if (info[content]?['info'] != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(top: 14),
                          decoration: BoxDecoration(
                            color: Colors.teal[50],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            info[content]!['info']!,
                            softWrap: true,
                            style: GoogleFonts.roboto(fontSize: 16, color: Colors.black87),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
