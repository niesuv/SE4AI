import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingItem extends ConsumerWidget {
  SettingItem(
      {super.key,
      this.text,
      this.icon,
      required this.onTap,
      this.color = Colors.black});

  final text;
  final icon;
  void Function() onTap;
  final color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
        ),
        padding: EdgeInsets.all(20),
        margin: EdgeInsets.all(15),
        child: Row(
          children: [
            Icon(
              icon,
              color: color,
              size: 25,
            ),
            SizedBox(
              width: 35,
            ),
            Text(
              text,
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 18, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
