import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';

class ClientLoginScreen extends StatefulWidget {
  const ClientLoginScreen({super.key});

  @override
  State<ClientLoginScreen> createState() => _ClientLoginScreenState();
}

class _ClientLoginScreenState extends State<ClientLoginScreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _link = TextEditingController();
  bool _useMagic = false;
  String? _error;
  bool _loading = false;

  Future<void> _submit() async {
    debugPrint('[ClientLoginScreen] Submit tapped, useMagic=$_useMagic');
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_useMagic) {
        if (_link.text.isEmpty) {
          await AuthService()
              .sendSignInLink(_email.text.trim(), Uri.base.toString());
          debugPrint('[ClientLoginScreen] Magic link sent');
          if (mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('Magic link sent')));
          }
        } else {
          await AuthService()
              .signInWithLink(_email.text.trim(), _link.text.trim());
          debugPrint('[ClientLoginScreen] Magic link login success');
        }
      } else {
        await AuthService()
            .signIn(email: _email.text.trim(), password: _password.text.trim());
        debugPrint('[ClientLoginScreen] Password login success');
      }
    } catch (e) {
      debugPrint('[ClientLoginScreen] Auth error: $e');
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _link.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Client Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/clearsky_logo.png', height: 80),
            const SizedBox(height: 12),
            const Text('Welcome to ClearSky', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 24),
            TextField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            if (!_useMagic)
              TextField(
                controller: _password,
                decoration: const InputDecoration(labelText: 'PIN or Password'),
                obscureText: true,
              ),
            if (_useMagic)
              TextField(
                controller: _link,
                decoration:
                    const InputDecoration(labelText: 'Paste magic link'),
              ),
            const SizedBox(height: 8),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: Text(_useMagic ? 'Continue' : 'Login'),
            ),
            TextButton(
              onPressed: _loading
                  ? null
                  : () => setState(() => _useMagic = !_useMagic),
              child:
                  Text(_useMagic ? 'Use password instead' : 'Use magic link'),
            ),
          ],
        ),
      ),
    );
  }
}
