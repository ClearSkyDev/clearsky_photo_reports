import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Screen for entering basic inspection details before photo capture.
class ProjectDetailsScreen extends StatefulWidget {
  const ProjectDetailsScreen({super.key});

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _clientNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _carrierController = TextEditingController();
  final TextEditingController _perilController = TextEditingController();

  bool _isSubmitting = false;

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('User not logged in');

      final docRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('inspections')
          .add({
        'clientName': _clientNameController.text,
        'address': _addressController.text,
        'carrier': _carrierController.text,
        'peril': _perilController.text,
        'createdAt': Timestamp.now(),
        'status': 'draft',
        'photos': [],
      });

      // Navigate to photo capture with inspection ID
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        '/capture',
        arguments: {'inspectionId': docRef.id},
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving project: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Inspection')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _clientNameController,
                decoration: const InputDecoration(labelText: 'Client Name'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Property Address'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _carrierController,
                decoration:
                    const InputDecoration(labelText: 'Insurance Carrier'),
              ),
              TextFormField(
                controller: _perilController,
                decoration: const InputDecoration(labelText: 'Peril Type'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitForm,
                child: _isSubmitting
                    ? const CircularProgressIndicator()
                    : const Text('Start Inspection'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
