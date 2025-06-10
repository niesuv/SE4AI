import 'package:agri_helper/widget/noteview.dart';
import 'package:agri_helper/widget/setting.dart';
import 'package:agri_helper/widget/socialview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agri_helper/appconstant.dart';
import 'package:agri_helper/widget/home.dart';
import 'package:agri_helper/ui/home_page.dart';
import 'package:agri_helper/screen/disease_wiki_screen.dart';

class MainApp extends ConsumerStatefulWidget {
  const MainApp({Key? key}) : super(key: key);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _MainAppState();
  }
}

class _MainAppState extends ConsumerState<MainApp> {
  int selectedIndex = 0;
  late final List<Widget> wid;

  @override
  void initState() {
    super.initState();
    wid = [
      Home(),
      NoteView(),
      HomePage(),
      const DiseaseWikiScreen(), // Thêm Wiki vào đây
      SocialView(),
      SettingView(),
    ];
  }

  void onTapNav(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: wid[selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        selectedItemColor: buttonBack,
        unselectedItemColor: Colors.black,
        onTap: onTapNav,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.edit_calendar_outlined),
            label: 'Notes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: 'Weather',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_florist),
            label: 'Wiki', // Tab mới
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.supervisor_account_sharp),
            label: 'Social',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}