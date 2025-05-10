import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agri_helper/appconstant.dart';

class ChangePasswordView extends ConsumerStatefulWidget {
  ChangePasswordView({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _ChangePasswordViewState();
  }
}

class _ChangePasswordViewState extends ConsumerState<ChangePasswordView> {
  var newPassword1 = "";
  var newPassword2 = "";
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
  }

  void _submitForm() {
    FocusScope.of(context).unfocus();
    final valid = _formKey.currentState!.validate();
    if (valid) {
      _formKey.currentState!.save();
      FirebaseAuth.instance.currentUser!
          .updatePassword(newPassword1)
          .then((value) {
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Đổi mật khẩu thành công!")));
      }).onError((error, stackTrace) {
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Đổi mật khẩu thất bại!")));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          title: Text(
            "Đổi mật khẩu",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                height: 1,
                color: Colors.grey,
              ),
              SizedBox(
                height: 20,
              ),
              Container(
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey, width: 10),
                    shape: BoxShape.circle, // Shape of the container
                    color: Colors.white60),
                child: Image.asset(
                  "assets/images/nongdan.png",
                  width: 150,
                ),
              ),
              SizedBox(
                height: 16,
              ),
              Container(
                padding: EdgeInsets.all(15),
                child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          obscureText: true,
                          decoration: InputDecoration(
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                            labelText: "Mật khẩu mới",
                          ),
                          onSaved: (newValue) {
                            newPassword1 = newValue!;
                          },
                          onChanged: (value) {
                            newPassword1 = value!;
                          },
                          validator: (value) {
                            if (value == null || value.trim().length < 6)
                              return "Vui long dien mat khau it nhat 6 ky tu!";
                            return null;
                          },
                        ),
                        SizedBox(
                          height: 30,
                        ),
                        TextFormField(
                          obscureText: true,
                          decoration: InputDecoration(
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                            labelText: "Nhập lại mật khẩu mới",
                          ),
                          onSaved: (value) {
                            newPassword2 = value!;
                          },
                          onChanged: (value) {
                            newPassword2 = value;
                          },
                          validator: (value) {
                            if (value != newPassword1)
                              return "2 mat khau khong giong nhau";
                            return null;
                          },
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
                              "Lưu thay đổi",
                              style: TextStyle(fontSize: 20),
                            ),
                          ),
                        ),
                      ],
                    )),
              )
            ],
          ),
        ),
      ),
    );
  }
}
