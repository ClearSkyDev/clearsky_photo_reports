import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../widgets/signature_pad.dart';
import '../../core/models/homeowner_signature.dart';

class ClientSignatureScreen extends StatefulWidget {
  final String reportId;
  const ClientSignatureScreen({super.key, required this.reportId});

  @override
  State<ClientSignatureScreen> createState() => _ClientSignatureScreenState();
}

class _ClientSignatureScreenState extends State<ClientSignatureScreen> {
  final TextEditingController _nameController = TextEditingController();
  Uint8List? _signature;

  void _onSave(Uint8List bytes, File file) {
    setState(() {
      _signature = bytes;
    });
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _signature == null) return;
    final sig = HomeownerSignature(
      name: name,
      image: base64Encode(_signature!),
    );
    await FirebaseFirestore.instance
        .collection('reports')
        .doc(widget.reportId)
        .update({
      'homeownerSignature': sig.toMap(),
      'signatureStatus': 'signed',
    });
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Signature submitted')));
      Navigator.pop(context, true);
    }
  }

  Future<void> _decline() async {
    final textController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Decline to Sign'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(labelText: 'Reason'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, textController.text.trim()),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    if (reason == null) return;
    await FirebaseFirestore.instance
        .collection('reports')
        .doc(widget.reportId)
        .update({
      'homeownerSignature': {
        'declined': true,
        'declineReason': reason,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
      'signatureStatus': 'declined',
    });
    if (mounted) {
      Navigator.pop(context, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Homeowner Signature')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Your Name'),
            ),
            const SizedBox(height: 12),
            SignaturePad(onSave: _onSave),
            const SizedBox(height: 20),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Submit'),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: _decline,
                  child: const Text('Decline'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
