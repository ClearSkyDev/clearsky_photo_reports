import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';

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
  final TextEditingController _projectNumberController = TextEditingController();
  final TextEditingController _claimNumberController = TextEditingController();
  final TextEditingController _appointmentController = TextEditingController();

  DateTime? _appointmentDate;

  final List<String> externalReportUrls = [];

  bool _isSubmitting = false;

  Future<void> _pickAndUploadExternalReport() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'csv'],
    );
    if (!mounted) return;
    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      final name = p.basename(path);
      try {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid == null) throw Exception('User not logged in');
        final ref = FirebaseStorage.instance
            .ref('users/$uid/external_reports/$name');
        final task = await ref.putFile(File(path));
        final url = await task.ref.getDownloadURL();
        if (!mounted) return;
        setState(() {
          externalReportUrls.add(url);
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload: $e')),
        );
      }
    }
  }

  Future<void> _pickAppointmentDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _appointmentDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
            _appointmentDate ?? DateTime.now()),
      );
      if (time != null) {
        setState(() {
          _appointmentDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
          _appointmentController.text =
              DateFormat('yyyy-MM-dd h:mm a').format(_appointmentDate!);
        });
      }
    }
  }

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
        'projectNumber': _projectNumberController.text,
        'claimNumber': _claimNumberController.text,
        if (_appointmentDate != null)
          'appointmentDate': Timestamp.fromDate(_appointmentDate!),
        'createdAt': Timestamp.now(),
        'status': 'draft',
        'photos': [],
        if (externalReportUrls.isNotEmpty)
          'externalReportUrls': externalReportUrls,
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
                controller: _projectNumberController,
                decoration: const InputDecoration(labelText: 'Project Number'),
              ),
              TextFormField(
                controller: _claimNumberController,
                decoration: const InputDecoration(labelText: 'Claim Number'),
              ),
              GestureDetector(
                onTap: _pickAppointmentDate,
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration:
                        const InputDecoration(labelText: 'Appointment Date'),
                    controller: _appointmentController,
                    readOnly: true,
                  ),
                ),
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
              const SizedBox(height: 12),
              ...externalReportUrls.map(
                (url) => ListTile(
                  title: Text(p.basename(url)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      setState(() {
                        externalReportUrls.remove(url);
                      });
                    },
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _pickAndUploadExternalReport,
                icon: const Icon(Icons.attach_file),
                label: const Text('Attach External Report'),
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

  @override
  void dispose() {
    _clientNameController.dispose();
    _addressController.dispose();
    _carrierController.dispose();
    _perilController.dispose();
    _projectNumberController.dispose();
    _claimNumberController.dispose();
    _appointmentController.dispose();
    super.dispose();
  }
}
