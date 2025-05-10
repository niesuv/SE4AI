import 'package:agri_helper/provider/note_provider.dart';
import 'package:agri_helper/provider/user_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserInfoCard extends ConsumerWidget {
  UserInfoCard({super.key, this.username});

  final String? username;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    print("Hi, ${username}");
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(32),
      ),
      elevation: 8,
      child: Container(
        padding: EdgeInsets.all(10),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                  shape: BoxShape.circle, // Shape of the container
                  color: Colors.white60),
              child: Image.asset(
                "assets/images/nongdan.png",
                width: 70,
              ),
            ),
            SizedBox(
              width: 16,
            ),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Hi, ${username}",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "Bắt đầu quản lý trang trại của bạn",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            )),
            IconButton(
              icon: Icon(
                Icons.logout,
                size: 30,
                color: Colors.red,
              ),
              onPressed: () {
                FirebaseAuth.instance.signOut();
                ref.read(NoteProvider.notifier).clear();
                ref.read(UserProvider.notifier).clear();
              },
            ),
            SizedBox(
              width: 25,
            )
          ],
        ),
      ),
    );
  }
}
