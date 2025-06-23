import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';

class SignUpProcessingScreen extends StatefulWidget {
  final String name;
  final String email;
  final String password;

  const SignUpProcessingScreen({
    super.key,
    required this.name,
    required this.email,
    required this.password,
  });

  @override
  State<SignUpProcessingScreen> createState() => _SignUpProcessingScreenState();
}

class _SignUpProcessingScreenState extends State<SignUpProcessingScreen> {
  @override
  void initState() {
    super.initState();
    _createAccount();
  }

  Future<void> _createAccount() async {
    try {
      await AuthService().signUp(
        email: widget.email,
        password: widget.password,
        companyId: '',
      );
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Signup failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Creating your account...'),
          ],
        ),
      ),
    );
  }
}
