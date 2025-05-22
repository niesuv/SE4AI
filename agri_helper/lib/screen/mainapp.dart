import 'package:agri_helper/widget/noteview.dart';
import 'package:agri_helper/widget/setting.dart';
import 'package:agri_helper/widget/socialview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agri_helper/appconstant.dart';
import 'package:agri_helper/widget/home.dart';
import 'package:agri_helper/ui/home_page.dart';

class MainApp extends ConsumerStatefulWidget {
  MainApp({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _MainAppState();
  }
}

class _MainAppState extends ConsumerState<MainApp> {
  int selectedIndex = 0;
  var wid;

  @override
  void initState() {
    super.initState();
    wid = [Home(), NoteView(), HomePage(), SocialView(), SettingView()];
  }

  void onTapNav(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentView;
    currentView = wid[selectedIndex];
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.edit_calendar_outlined),
            label: 'Notes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore), // <-- Icon cho HomePage()
            label: 'Explore',          // <-- Đặt tên phù hợp
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.supervisor_account_sharp),
            label: 'Social',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          )
        ],
        currentIndex: selectedIndex,
        selectedItemColor: buttonBack,
        unselectedItemColor: Colors.black,
        onTap: onTapNav,
      ),
      body: currentView,
    );
  }
}
