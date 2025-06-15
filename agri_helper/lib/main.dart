import 'package:agri_helper/services/NotificationService.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agri_helper/screen/auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:agri_helper/screen/mainapp.dart';
import 'package:agri_helper/screen/disease_wiki_screen.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';

Future<void> requestNotificationPermission() async {
  final status = await Permission.notification.status;
  if (!status.isGranted) {
    await Permission.notification.request();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  await NotificationService.initialize();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await dotenv.load(fileName: ".env");
  await requestNotificationPermission();
  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Harvest',
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: Text("Loading")),
            );
          }
          if (snapshot.hasData) {
            return SafeArea(child: MainApp());
          } else {
            return AuthScreen();
          }
        },
      ),
      theme: ThemeData(
        useMaterial3: true, // 🔥 Bật Material 3
        colorSchemeSeed: Colors.green,
        brightness: Brightness.light,
      ),
      routes: {
        '/wiki': (_) => const DiseaseWikiScreen(),
      },
    );
  }
}