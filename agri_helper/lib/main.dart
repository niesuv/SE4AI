import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agri_helper/screen/auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:agri_helper/screen/mainapp.dart';
import 'package:agri_helper/screen/disease_wiki_screen.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await dotenv.load(fileName: ".env");

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
      routes: {
        '/wiki': (_) => const DiseaseWikiScreen(),
      },
    );
  }
}