import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      print('SplashScreen loaded');
    }
    Future.delayed(const Duration(seconds: 2), () {
      if (kDebugMode) {
        print('Attempting to determine start screen...');
      }
      if (!mounted) return;
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        if (kDebugMode) {
          print('User already logged in: ${user.uid}');
        }
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        if (kDebugMode) {
          print('No authenticated user, showing login.');
        }
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF007BFF),
      body: Center(
        child: Image.asset(
          'assets/splash.png',
          width: 200,
        ),
      ),
    );
  }
}
