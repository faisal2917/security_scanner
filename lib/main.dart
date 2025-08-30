import 'package:flutter/material.dart';
import 'package:security_scanner/presentation/security_checker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Security Scanner",
      debugShowCheckedModeBanner: false,
      home: SecurityCheckerScreen(),
    );
  }
}