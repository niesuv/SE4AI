import 'package:agri_helper/appconstant.dart';
import 'package:agri_helper/provider/note_provider.dart';
import 'package:agri_helper/provider/user_provider.dart';
import 'package:agri_helper/widget/change_infomation_view.dart';
import 'package:agri_helper/widget/change_password.dart';
import 'package:agri_helper/widget/setting_item.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingView extends ConsumerStatefulWidget {
  SettingView({super.key});
  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _SettingViewState();
  }
}

class _SettingViewState extends ConsumerState<SettingView> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: background,
      padding: EdgeInsets.all(15),
      child: Column(
        children: [
          Text(
            "Cài đặt",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey)),
            ),
            child: SizedBox(
              height: 10,
              width: double.infinity,
            ),
          ),
          SettingItem(
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) {
                  return ChangeInfomationView();
                },
              ));
            },
            icon: Icons.account_box,
            text: "Chỉnh sửa hồ sơ",
          ),
          SettingItem(
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) {
                  return ChangePasswordView();
                },
              ));
            },
            icon: Icons.vpn_key,
            text: "Đổi mật khẩu",
          ),
          SettingItem(
            onTap: () {
              FirebaseAuth.instance.signOut();
              ref.read(NoteProvider.notifier).clear();
              ref.read(UserProvider.notifier).clear();
            },
            icon: Icons.arrow_back,
            text: "Đăng xuất",
            color: Colors.pink,
          ),
        ],
      ),
    );
  }
}
