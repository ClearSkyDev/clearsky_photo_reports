import 'package:flutter/material.dart';

import '../models/inspection_metadata.dart';
import 'photo_upload_screen.dart';

class MetadataScreen extends StatefulWidget {
  const MetadataScreen({super.key});

  @override
  State<MetadataScreen> createState() => _MetadataScreenState();
}

class _MetadataScreenState extends State<MetadataScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _clientNameController = TextEditingController();
  final TextEditingController _propertyAddressController = TextEditingController();
  final TextEditingController _insuranceCarrierController = TextEditingController();
  final TextEditingController _inspectorNameController = TextEditingController();
  DateTime _inspectionDate = DateTime.now();
  PerilType _selectedPeril = PerilType.wind;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _inspectionDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _inspectionDate = picked;
      });
    }
  }

  void _continue() {
    if (_formKey.currentState?.validate() ?? false) {
      final metadata = InspectionMetadata(
        clientName: _clientNameController.text,
        propertyAddress: _propertyAddressController.text,
        inspectionDate: _inspectionDate,
        insuranceCarrier: _insuranceCarrierController.text.isNotEmpty
            ? _insuranceCarrierController.text
            : null,
        perilType: _selectedPeril,
        inspectorName: _inspectorNameController.text.isNotEmpty
            ? _inspectorNameController.text
            : null,
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PhotoUploadScreen(metadata: metadata),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inspection Metadata')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _clientNameController,
                decoration: const InputDecoration(labelText: 'Client Name'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _propertyAddressController,
                decoration: const InputDecoration(labelText: 'Property Address'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              GestureDetector(
                onTap: _pickDate,
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration:
                        const InputDecoration(labelText: 'Inspection Date'),
                    controller: TextEditingController(
                      text: _inspectionDate.toLocal().toString().split(' ')[0],
                    ),
                  ),
                ),
              ),
              TextFormField(
                controller: _insuranceCarrierController,
                decoration:
                    const InputDecoration(labelText: 'Insurance Carrier'),
              ),
              DropdownButtonFormField<PerilType>(
                value: _selectedPeril,
                decoration: const InputDecoration(labelText: 'Peril Type'),
                items: PerilType.values
                    .map(
                      (p) => DropdownMenuItem(
                        value: p,
                        child: Text(p.name[0].toUpperCase() + p.name.substring(1)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedPeril = value;
                    });
                  }
                },
              ),
              TextFormField(
                controller: _inspectorNameController,
                decoration: const InputDecoration(labelText: 'Inspector Name'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _continue,
                child: const Text('Continue to Photo Upload'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
