import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/models/inspector_profile.dart';
import '../../core/utils/profile_storage.dart';
import 'capture_signature_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  InspectorRole _role = InspectorRole.inspector;
  Uint8List? _signature;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await ProfileStorage.load();
    if (profile != null) {
      _nameController.text = profile.name;
      _emailController.text = profile.email;
      _phoneController.text = profile.phone ?? '';
      _companyController.text = profile.company ?? '';
      _role = profile.role;
      if (profile.signature != null) {
        _signature = base64Decode(profile.signature!);
      }
    }
    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _captureSignature() async {
    final result = await Navigator.push<Uint8List>(
      context,
      MaterialPageRoute(builder: (_) => const CaptureSignatureScreen()),
    );
    if (result != null) {
      if (!mounted) return;
      setState(() {
        _signature = result;
      });
    }
  }

  Future<void> _save() async {
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
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Profile saved')));
    }
  }

  Future<void> _logout() async {
    await ProfileStorage.clear();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Inspector Profile')),
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
              label: const Text('Change Signature'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/notifications'),
              child: const Text('Notification Settings'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _save,
              child: const Text('Save'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _logout,
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}
