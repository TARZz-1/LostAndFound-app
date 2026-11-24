import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'pages/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Objetos Perdidos USM',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        // cambia color y tonalidades de la app completa
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF003DA5),
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          //cambia el color del appbar
          backgroundColor: Color(0xFF003DA5),
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 2,
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}
