import 'package:flutter/material.dart';

import 'screens/login_screen.dart';

void main() => runApp(const PhysicsApp());

class PhysicsApp extends StatelessWidget {
  const PhysicsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Physics Platform',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B1020),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.dark,
        ),
      ),
      home: const LoginScreen(),
    );
  }
}
