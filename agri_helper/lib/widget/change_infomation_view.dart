import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agri_helper/provider/user_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agri_helper/appconstant.dart';

class ChangeInfomationView extends ConsumerStatefulWidget {
  ChangeInfomationView({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _ChangeInfomationViewState();
  }
}

class _ChangeInfomationViewState extends ConsumerState<ChangeInfomationView> {
  var _phoneNumber = "";
  var _username = "";
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _phoneNumber = ref.read(UserProvider)["phone"]!;
    _username = ref.read(UserProvider)["username"]!;
  }

  void _submitForm() async {
    FocusScope.of(context).unfocus();
    final valid = _formKey.currentState!.validate();
    if (valid) {
      setState(() {
        _isLoading = true;
      });

      try {
        _formKey.currentState!.save();
        await FirebaseFirestore.instance
            .collection("users")
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .update({
          "username": _username,
          "phone": _phoneNumber
        });

        ref.read(UserProvider.notifier).setUsername(_username);
        ref.read(UserProvider.notifier).setphone(_phoneNumber);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cập nhật thông tin thành công'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi: Không thể cập nhật thông tin. ${error.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          title: Text(
            "Chỉnh sửa hồ sơ",
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
                          decoration: InputDecoration(
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                            labelText: "Họ và tên",
                          ),
                          initialValue: _username,
                          onSaved: (newValue) {
                            _username = newValue!;
                          },
                          validator: (value) {
                            if (value == null || value.trim().length < 4)
                              return "Vui long dien ten it nhat 4 ky tu!";
                            return null;
                          },
                        ),
                        SizedBox(
                          height: 30,
                        ),
                        TextFormField(
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                            labelText: "Số điện thoại",
                          ),
                          initialValue: _phoneNumber,
                          onSaved: (value) {
                            _phoneNumber = value!;
                          },
                          validator: (value) {
                            if (value == null || value.length < 10)
                              return "Vui long Nhap dung so dien thoai it nhat 10 so";
                            return null;
                          },
                        ),                        Container(
                          margin: EdgeInsets.only(top: 40),
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton(
                            style: TextButton.styleFrom(
                              backgroundColor: buttonBack,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: _isLoading ? null : _submitForm,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
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
