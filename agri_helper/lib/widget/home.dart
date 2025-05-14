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

class Home extends ConsumerStatefulWidget {
  Home({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _HomeState();
  }
}

class _HomeState extends ConsumerState<Home> {
  // User info
  String username = '';

  // Image and result
  File? _imagePick;
  String content = '';

  // Fruit selection
  final List<String> fruitTypes = ['apple', 'strawberry', 'rice', 'potato', 'durian', 'mango', 'corn', 'banana', 'grape', 'pepper', 'tomato', 'mango_Fruit', 'orange', 'peach'];
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
        username = data == null ? 'Khong xac dinh' : data['username'];
      });
      if (data != null) {
        ref.read(UserProvider.notifier).setUsername(data['username']);
        ref.read(UserProvider.notifier).setphone(data['phone']);
      }
    });
  }

  void _submitImage() async {
    if (_imagePick == null) return;

    final uri = Uri.parse(apilua);
    final request = http.MultipartRequest('POST', uri);

    // Send selected fruit type
    request.fields['fruit'] = selectedFruit;

    // Attach image file
    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        _imagePick!.path,
        contentType: MediaType('image', 'jpeg'),
      ),
    );

    try {
      // Timeout after 60 seconds
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
        });
      } else {
        setState(() {
          content = 'error: HTTP \${response.statusCode}';
        });
      }
    } on TimeoutException {
      setState(() {
        content = 'error: timeout';
      });
    } catch (e) {
      setState(() {
        content = 'error: \$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      color: background,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UserInfoCard(username: username),
            const SizedBox(height: 16),

            // Fruit type dropdown
            const Text('Chọn loại cây:', style: TextStyle(fontSize: 16)),
            DropdownButton<String>(
              value: selectedFruit,
              items: fruitTypes.map((fruit) {
                return DropdownMenuItem(
                  value: fruit,
                  child: Text(fruit),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => selectedFruit = value);
                }
              },
            ),
            const SizedBox(height: 16),

            const Text(
              'Chẩn đoán bệnh lúa',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),

            // Image picker
            ImagePickerWidget(onPickImage: (img) {
              setState(() {
                _imagePick = img;
              });
            }),

            // Submit button
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 10),
              child: ElevatedButton(
                style: TextButton.styleFrom(
                  backgroundColor: buttonBack,
                  foregroundColor: Colors.white,
                ),
                onPressed: _submitImage,
                child: const Text(
                  'Bắt đầu phân tích',
                  style: TextStyle(fontSize: 20),
                ),
              ),
            ),

            // Result
            if (content.isNotEmpty)
              Column(
                children: [
                  Container(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: content == 'healthy'
                            ? const Color.fromARGB(255, 32, 209, 65)
                            : Colors.amber,
                      ),
                      onPressed: () {},
                      child: Text(
                        'Kết quả: ${info[content]!["name"]}',
                        style: TextStyle(
                          color: content == 'healthy'
                              ? Colors.white
                              : const Color.fromARGB(255, 194, 41, 27),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    color: Colors.white60,
                    margin: const EdgeInsets.only(top: 15),
                    child: Text(
                      info[content]!['info']!,
                      softWrap: true,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
