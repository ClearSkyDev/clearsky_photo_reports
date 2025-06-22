import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
    final ctx = context;
    Future.delayed(const Duration(seconds: 2), () {
      if (kDebugMode) {
        print('Attempting to navigate to home...');
      }
      if (mounted) {
        Navigator.pushReplacementNamed(ctx, '/home');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'assets/images/clearsky_logo.png',
          width: 200,
        ),
      ),
    );
  }
}
