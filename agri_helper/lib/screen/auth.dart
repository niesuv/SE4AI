import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agri_helper/appconstant.dart';

final _fireBase = FirebaseAuth.instance;

class AuthScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _AuthScreenState();
  }
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  var username = "";
  var email = "";
  var password = "";

  var signup = true;
  final formKey = GlobalKey<FormState>();
  void _submitForm() async {
    FocusScope.of(context).unfocus();
    final isValid = formKey.currentState!.validate();
    if (isValid) formKey.currentState!.save();

    try {
      if (signup) {
        final userAuth = await _fireBase.createUserWithEmailAndPassword(
            email: email, password: password);
        FirebaseFirestore.instance
            .collection("users")
            .doc(userAuth.user!.uid)
            .set({"username": username, "email": email, "phone": ""}).onError(
                (e, _) => print("Error writing document: $e"));
      } else {
        final userAuth = await _fireBase.signInWithEmailAndPassword(
            email: email, password: password);
        print(userAuth);
      }
    } on FirebaseAuthException catch (err) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Fail to sign, ${err.toString()}")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: greenBack,
      body: SingleChildScrollView(
        child: Container(
            padding: EdgeInsets.all(20),
            margin: EdgeInsets.only(top: 100),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  signup ? "Tạo Tài khoản" : "Chào Mừng Trở lại",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                  textAlign: TextAlign.left,
                ),
                SizedBox(
                  height: 16,
                ),
                Text(
                  signup
                      ? "Bắt đầu quản lý nông trại của bạn"
                      : "Đừng quên xem thời tiết thường xuyên",
                ),
                SizedBox(
                  height: 16,
                ),
                Form(
                    key: formKey,
                    child: Column(
                      children: [
                        if (signup)
                          TextFormField(
                            decoration: InputDecoration(
                              enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              labelText: "Họ và tên",
                            ),
                            onSaved: (newValue) {
                              username = newValue!;
                            },
                            validator: (value) {
                              if (value == null || value.trim().length < 4)
                                return "Vui long dien ten it nhat 4 ky tu!";
                              return null;
                            },
                          ),
                        SizedBox(
                          height: 20,
                        ),
                        TextFormField(
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                            labelText: "Email",
                          ),
                          onSaved: (value) {
                            email = value!;
                          },
                          validator: (value) {
                            if (value == null || !value.contains("@"))
                              return "Vui long Nhap dung dinh dang email!";
                            return null;
                          },
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        TextFormField(
                          obscureText: true,
                          decoration: InputDecoration(
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                            labelText: "Mật khẩu",
                          ),
                          onSaved: (newValue) {
                            password = newValue!;
                          },
                          validator: (value) {
                            if (value == null || value.length < 6)
                              return "Vui long dien mat khau it nhat 6 ky tu!";
                            return null;
                          },
                        ),
                        SizedBox(
                          height: 16,
                        ),
                        Container(
                          margin: EdgeInsets.only(top: 40),
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton(
                            style: TextButton.styleFrom(
                              backgroundColor: buttonBack,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: _submitForm,
                            child: Text(
                              signup ? 'Đăng ký' : "Đăng nhập",
                              style: TextStyle(fontSize: 20),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 16,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(signup
                                ? "Bạn đã có tài khoản "
                                : "Bạn chưa có tài khoản "),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  signup = !signup;
                                });
                              },
                              child: Text(
                                signup ? 'Đăng nhập' : "Đăng ký",
                                style:
                                    TextStyle(fontSize: 18, color: buttonBack),
                              ),
                            )
                          ],
                        )
                      ],
                    ))
              ],
            )),
      ),
    );
  }
}
