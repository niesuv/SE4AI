// import 'package:agri_helper/widget/noteview.dart';
// import 'package:agri_helper/widget/setting.dart';
// import 'package:agri_helper/widget/socialview.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:agri_helper/appconstant.dart';
// import 'package:agri_helper/widget/home.dart';

// class MainApp extends ConsumerStatefulWidget {
//   MainApp({super.key});

//   @override
//   ConsumerState<ConsumerStatefulWidget> createState() {
//     return _MainAppState();
//   }
// }

// class _MainAppState extends ConsumerState<MainApp> {
//   int selectedIndex = 0;
//   var wid;

//   @override
//   void initState() {
//     super.initState();
//     wid = [Home(), NoteView(), SocialView(), SettingView()];
//   }

//   void onTapNav(int index) {
//     setState(() {
//       selectedIndex = index;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final currentView;
//     currentView = wid[selectedIndex];
//     return Scaffold(
//       bottomNavigationBar: BottomNavigationBar(
//         items: [
//           BottomNavigationBarItem(
//             icon: Icon(Icons.home),
//             label: 'Home',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.edit_calendar_outlined),
//             label: 'Notes',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.supervisor_account_sharp),
//             label: 'Social',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.settings),
//             label: 'Settings',
//           )
//         ],
//         currentIndex: selectedIndex,
//         selectedItemColor: buttonBack,
//         unselectedItemColor: Colors.black,
//         onTap: onTapNav,
//       ),
//       body: currentView,
//     );
//   }
// }
// lib/screen/mainapp.dart
import 'package:agri_helper/widget/home.dart';
import 'package:agri_helper/widget/noteview.dart';
import 'package:agri_helper/widget/forum.dart';         // ← import mới
import 'package:agri_helper/widget/socialview.dart';
import 'package:agri_helper/widget/setting.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agri_helper/appconstant.dart';

class MainApp extends ConsumerStatefulWidget {
  const MainApp({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _MainAppState();
  }
}

class _MainAppState extends ConsumerState<MainApp> {
  int selectedIndex = 0;
  late final List<Widget> _views;

  @override
  void initState() {
    super.initState();
    _views = [
      Home(),
      NoteView(),
      ForumPage(),     // ← thêm ForumPage vào danh sách
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
      body: _views[selectedIndex],
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
          BottomNavigationBarItem(         // ← tab Forum mới
            icon: Icon(Icons.forum_outlined),
            label: 'Forum',
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
      ),
    );
  }
}
