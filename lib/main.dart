import 'package:flutter/material.dart';
import 'ekranlar/home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Okuma Prototipi',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFFFF8E1),
      ),
      home: const HomePage(),
    );
  }
}