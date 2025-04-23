import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class NavItem extends StatelessWidget {
  NavItem(
      {super.key,
      required this.name,
      required this.onTap,
      required this.color,
      required this.icon});

  final String name;
  final icon;
  void Function() onTap;
  final color;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Icon(
        icon,
        size: 50,
        color: color,
      ),
    );
  }
}
