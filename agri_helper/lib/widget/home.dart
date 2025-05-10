import 'dart:convert';

import 'package:agri_helper/appconstant.dart';
import 'package:agri_helper/benh_lua.dart';
import 'package:agri_helper/provider/user_provider.dart';
import 'package:agri_helper/widget/ImagePickerWidget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agri_helper/widget/userinfo.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;

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
  String content = "";
  @override
  void initState() {
    super.initState();
    final name = ref.read(UserProvider);
    if (name["username"] != "") {
      username = name["username"]!;
      return;
    }
    final res = FirebaseFirestore.instance
        .collection("users")
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get();
    res.then((value) {
      if (value.data() == null) {
        username = "Khong xac dinh";
      } else {
        setState(() {
          username = value.data()!["username"];
        });
      }
      ref.read(UserProvider.notifier).setUsername(username);
      ref.read(UserProvider.notifier).setphone(value.data()!["phone"]);
    });
  }

  void _submitImage() async {
    if (_imagePick != null) {
      var request = http.MultipartRequest('POST', Uri.parse(apilua));
      request.files
          .add(await http.MultipartFile.fromPath('image', _imagePick!.path));

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        final res = await response.stream.bytesToString();
        setState(() {
          content = json.decode(res)["data"].toString().trim();
        });
      } else {
        setState(() {
          content = "error";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(15),
      color: background,
      child: SingleChildScrollView(
        child: Column(
          children: [
            UserInfoCard(
              username: username,
            ),
            SizedBox(
              height: 16,
            ),
            Text("Chẩn đoán bệnh lúa",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            ImagePickerWidget(onPickImage: (img) {
              setState(() {
                _imagePick = img;
              });
            }),
            Container(
              width: double.infinity,
              margin: EdgeInsets.only(top: 10),
              child: ElevatedButton(
                style: TextButton.styleFrom(
                  backgroundColor: buttonBack,
                  foregroundColor: Colors.white,
                ),
                onPressed: _submitImage,
                child: Text(
                  "Bắt đầu phân tích",
                  style: TextStyle(fontSize: 20),
                ),
              ),
            ),
            if (content != '')
              Column(
                children: [
                  Container(
                    width: double.infinity,
                    child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: content == "healthy"
                                ? Color.fromARGB(255, 32, 209, 65)
                                : Colors.amber),
                        onPressed: () {},
                        child: Text(
                          "Kết quả: ${info[content]!["name"]}",
                          style: TextStyle(
                              color: content == "healthy"
                                  ? Colors.white
                                  : Color.fromARGB(255, 194, 41, 27)),
                        )),
                  ),
                  Container(
                    padding: EdgeInsets.all(10),
                    color: Colors.white60,
                    margin: EdgeInsets.only(top: 15),
                    child: Text(
                      info[content]!["info"]!,
                      softWrap: true,
                    ),
                  ),
                ],
              )
          ],
        ),
      ),
    );
  }
}
