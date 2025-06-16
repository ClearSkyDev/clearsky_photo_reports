import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/inspector_profile.dart';
import '../utils/profile_storage.dart';
import 'capture_signature_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  InspectorRole _role = InspectorRole.inspector;
  Uint8List? _signature;

  Future<void> _captureSignature() async {
    final result = await Navigator.push<Uint8List>(
      context,
      MaterialPageRoute(builder: (_) => const CaptureSignatureScreen()),
    );
    if (result != null) {
      setState(() {
        _signature = result;
      });
    }
  }

  Future<void> _login() async {
    final profile = InspectorProfile(
      id: _emailController.text.trim(),
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim().isNotEmpty
          ? _phoneController.text.trim()
          : null,
      company: _companyController.text.trim().isNotEmpty
          ? _companyController.text.trim()
          : null,
      signature: _signature != null ? base64Encode(_signature!) : null,
      role: _role,
    );
    await ProfileStorage.save(profile);
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inspector Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
            TextField(
              controller: _companyController,
              decoration: const InputDecoration(labelText: 'Company'),
            ),
            DropdownButtonFormField<InspectorRole>(
              value: _role,
              decoration: const InputDecoration(labelText: 'Role'),
              items: InspectorRole.values
                  .map(
                    (r) => DropdownMenuItem(
                      value: r,
                      child: Text(r.name),
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _role = val;
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            if (_signature != null)
              Image.memory(
                _signature!,
                height: 80,
              ),
            TextButton.icon(
              onPressed: _captureSignature,
              icon: const Icon(Icons.border_color),
              label: const Text('Add Signature'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _login,
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
