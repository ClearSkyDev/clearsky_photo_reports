import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Screen for creating a new inspection and saving it to Firestore.
class CreateInspectionScreen extends StatefulWidget {
  const CreateInspectionScreen({super.key});

  @override
  State<CreateInspectionScreen> createState() => _CreateInspectionScreenState();
}

class _CreateInspectionScreenState extends State<CreateInspectionScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _clientNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _projectNumberController = TextEditingController();
  final TextEditingController _claimNumberController = TextEditingController();
  final TextEditingController _insuranceCarrierController = TextEditingController();
  final TextEditingController _perilTypeController = TextEditingController();
  final TextEditingController _appointmentController = TextEditingController();

  DateTime? _appointmentDate;
  bool _saving = false;

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _appointmentDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (!mounted) return;
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_appointmentDate ?? DateTime.now()),
      );
      if (!mounted) return;
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
              '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${time.format(context)}';
        });
      }
    }
  }

  Future<void> _createInspection() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final docRef = await FirebaseFirestore.instance
          .collection('inspections')
          .add({
        'clientName': _clientNameController.text.trim(),
        'propertyAddress': _addressController.text.trim(),
        'projectNumber': _projectNumberController.text.trim(),
        'claimNumber': _claimNumberController.text.trim(),
        'insuranceCarrier': _insuranceCarrierController.text.trim(),
        'perilType': _perilTypeController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        if (_appointmentDate != null)
          'appointmentDate': Timestamp.fromDate(_appointmentDate!),
        'createdAt': Timestamp.now(),
        'createdBy': uid,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inspection created successfully')),
      );
      Navigator.pushNamed(context, '/projectDetails', arguments: docRef);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create inspection: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _clientNameController.dispose();
    _addressController.dispose();
    _projectNumberController.dispose();
    _claimNumberController.dispose();
    _insuranceCarrierController.dispose();
    _perilTypeController.dispose();
    _appointmentController.dispose();
    super.dispose();
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
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Property Address'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _projectNumberController,
                decoration: const InputDecoration(labelText: 'Project Number'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _claimNumberController,
                decoration: const InputDecoration(labelText: 'Claim Number'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _insuranceCarrierController,
                decoration: const InputDecoration(labelText: 'Insurance Carrier'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _perilTypeController,
                decoration: const InputDecoration(labelText: 'Peril Type'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              GestureDetector(
                onTap: _pickDate,
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: _appointmentController,
                    decoration:
                        const InputDecoration(labelText: 'Appointment Date'),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Required'
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saving ? null : _createInspection,
                child: _saving
                    ? const CircularProgressIndicator()
                    : const Text('Create Inspection'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
