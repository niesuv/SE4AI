import 'package:agri_helper/widget/noteview.dart';
import 'package:agri_helper/widget/setting.dart';
import 'package:agri_helper/widget/socialview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agri_helper/appconstant.dart';
import 'package:agri_helper/widget/home.dart';
import 'package:agri_helper/ui/home_page.dart';
import 'package:agri_helper/screen/disease_wiki_screen.dart';
import 'package:agri_helper/screen/chat_bot_screen.dart';

class MainApp extends ConsumerStatefulWidget {
  const MainApp({Key? key}) : super(key: key);

  @override
  ConsumerState<MainApp> createState() => _MainAppState();
}

class _MainAppState extends ConsumerState<MainApp>
    with AutomaticKeepAliveClientMixin {
  int selectedIndex = 0;
  late final List<Widget> wid;

  @override
  void initState() {
    super.initState();
    wid = [
      Home(),
      NoteView(),
      HomePage(),
      const DiseaseWikiScreen(),
      const ChatBotScreen(),
      SocialView(),
      SettingView(),
    ];
  }

  void onTapNav(int index) {
    setState(() => selectedIndex = index);
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F7),
      body: IndexedStack(
        index: selectedIndex,
        children: wid,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        selectedItemColor: buttonBack,
        unselectedItemColor: Colors.black,
        onTap: onTapNav,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: false,
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
            label: 'Wiki',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.smart_toy),
            label: 'Chat',
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
