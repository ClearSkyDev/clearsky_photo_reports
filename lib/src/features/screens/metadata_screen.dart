import 'package:flutter/material.dart';
import '../../core/utils/profile_storage.dart';

import '../../core/models/inspection_metadata.dart';
import '../../core/models/inspection_type.dart';
import '../../core/models/checklist.dart';
import '../../core/models/checklist_template.dart';
import '../../core/models/peril_type.dart';
import 'photo_upload_screen.dart';
import '../../core/models/report_template.dart';
import '../../core/utils/template_store.dart';
import '../../core/utils/quick_report_preferences.dart';

class MetadataScreen extends StatefulWidget {
  final InspectionMetadata? initialMetadata;
  final ReportTemplate? initialTemplate;

  const MetadataScreen({super.key, this.initialMetadata, this.initialTemplate});

  @override
  State<MetadataScreen> createState() => _MetadataScreenState();
}

class _MetadataScreenState extends State<MetadataScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _clientNameController = TextEditingController();
  final TextEditingController _propertyAddressController =
      TextEditingController();
  final TextEditingController _insuranceCarrierController =
      TextEditingController();
  final TextEditingController _inspectorNameController =
      TextEditingController();
  final TextEditingController _reportIdController = TextEditingController();
  final TextEditingController _weatherNotesController = TextEditingController();
  final TextEditingController _partnerCodeController = TextEditingController();
  DateTime _inspectionDate = DateTime.now();
  PerilType _selectedPeril = PerilType.wind;
  InspectionType _selectedType = InspectionType.residentialRoof;
  Set<InspectorReportRole> _selectedRole = {InspectorReportRole.ladderAssist};
  List<ReportTemplate> _templates = [];
  ReportTemplate? _selectedTemplate;
  bool _quickEnabled = false;

  @override
  void initState() {
    super.initState();
    QuickReportPreferences.isEnabled().then((v) {
      if (mounted) setState(() => _quickEnabled = v);
    });
    if (widget.initialMetadata != null) {
      final meta = widget.initialMetadata!;
      _clientNameController.text = meta.clientName;
      _propertyAddressController.text = meta.propertyAddress;
      _inspectionDate = meta.inspectionDate;
      _selectedPeril = meta.perilType;
      _selectedType = meta.inspectionType;
      _insuranceCarrierController.text = meta.insuranceCarrier ?? '';
      _inspectorNameController.text = meta.inspectorName ?? '';
      _reportIdController.text = meta.reportId ?? '';
      _weatherNotesController.text = meta.weatherNotes ?? '';
      _partnerCodeController.text = meta.partnerCode ?? '';
      _selectedRole = Set.from(meta.inspectorRoles);
    } else {
      _loadProfile();
    }
    _loadTemplates();
  }

  Future<void> _loadProfile() async {
    final profile = await ProfileStorage.load();
    if (profile != null) {
      if (_inspectorNameController.text.isEmpty) {
        _inspectorNameController.text = profile.name;
      }
    }
  }

  Future<void> _loadTemplates() async {
    final items = await TemplateStore.loadTemplates();
    setState(() {
      _templates = items;
      if (_templates.isNotEmpty) {
        if (widget.initialTemplate != null) {
          _selectedTemplate = _templates.firstWhere(
            (t) => t.id == widget.initialTemplate!.id,
            orElse: () => _templates.first,
          );
        } else {
          _selectedTemplate = _templates.first;
        }
        if (widget.initialMetadata == null) {
          _applyTemplate(_selectedTemplate!);
        }
      }
    });
  }

  void _applyTemplate(ReportTemplate template) {
    final meta = template.defaultMetadata;
    if (meta['clientName'] != null) {
      _clientNameController.text = meta['clientName'];
    }
    if (meta['propertyAddress'] != null) {
      _propertyAddressController.text = meta['propertyAddress'];
    }
    if (meta['inspectorName'] != null) {
      _inspectorNameController.text = meta['inspectorName'];
    }
    if (meta['weatherNotes'] != null) {
      _weatherNotesController.text = meta['weatherNotes'];
    }
  }

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
        inspectionType: _selectedType,
        inspectorName: _inspectorNameController.text.isNotEmpty
            ? _inspectorNameController.text
            : null,
        inspectorRoles: _selectedRole,
        reportId: _reportIdController.text.isNotEmpty
            ? _reportIdController.text
            : null,
        weatherNotes: _weatherNotesController.text.isNotEmpty
            ? _weatherNotesController.text
            : null,
        partnerCode: _partnerCodeController.text.isNotEmpty
            ? _partnerCodeController.text
            : null,
      );
      final template = defaultChecklists.firstWhere(
        (c) =>
            c.roofType == _selectedType &&
            c.claimType == _selectedPeril &&
            _selectedRole.contains(c.role),
        orElse: () => defaultChecklists.first,
      );
      inspectionChecklist.loadTemplate(template);
      inspectionChecklist.markComplete('Metadata Saved');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PhotoUploadScreen(
            metadata: metadata,
            template: _selectedTemplate,
          ),
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
              SwitchListTile(
                title: const Text('Quick Report Mode'),
                value: _quickEnabled,
                onChanged: (v) {
                  setState(() => _quickEnabled = v);
                  QuickReportPreferences.setEnabled(v);
                },
              ),
              if (_templates.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: _selectedTemplate?.id,
                  decoration:
                      const InputDecoration(labelText: 'Inspection Template'),
                  items: _templates
                      .map(
                        (t) => DropdownMenuItem(
                          value: t.id,
                          child: Text(t.name),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    final template = _templates.firstWhere((t) => t.id == val,
                        orElse: () => _templates.first);
                    setState(() {
                      _selectedTemplate = template;
                      _applyTemplate(template);
                    });
                  },
                ),
              TextFormField(
                controller: _clientNameController,
                decoration: const InputDecoration(labelText: 'Client Name'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _propertyAddressController,
                decoration:
                    const InputDecoration(labelText: 'Property Address'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              GestureDetector(
                onTap: _pickDate,
                child: Semantics(
                  label: 'Select inspection date',
                  button: true,
                  child: AbsorbPointer(
                    child: TextFormField(
                      decoration:
                          const InputDecoration(labelText: 'Inspection Date'),
                      controller: TextEditingController(
                        text:
                            _inspectionDate.toLocal().toString().split(' ')[0],
                      ),
                      readOnly: true,
                    ),
                  ),
                ),
              ),
              TextFormField(
                controller: _insuranceCarrierController,
                decoration:
                    const InputDecoration(labelText: 'Insurance Carrier'),
              ),
              DropdownButtonFormField<InspectionType>(
                value: _selectedType,
                decoration: const InputDecoration(labelText: 'Inspection Type'),
                items: InspectionType.values
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child:
                            Text(t.name[0].toUpperCase() + t.name.substring(1)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedType = value;
                    });
                  }
                },
              ),
              DropdownButtonFormField<PerilType>(
                value: _selectedPeril,
                decoration: const InputDecoration(labelText: 'Peril Type'),
                items: PerilType.values
                    .map(
                      (p) => DropdownMenuItem(
                        value: p,
                        child:
                            Text(p.name[0].toUpperCase() + p.name.substring(1)),
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
              Wrap(
                spacing: 4,
                children: [
                  for (final r in InspectorReportRole.values)
                    FilterChip(
                      label: Text(r.name.replaceAll('_', ' ')),
                      selected: _selectedRole.contains(r),
                      onSelected: (val) {
                        setState(() {
                          if (val) {
                            _selectedRole.add(r);
                          } else {
                            _selectedRole.remove(r);
                          }
                        });
                      },
                    ),
                ],
              ),
              TextFormField(
                controller: _inspectorNameController,
                decoration: const InputDecoration(labelText: 'Inspector Name'),
              ),
              TextFormField(
                controller: _reportIdController,
                decoration: const InputDecoration(labelText: 'Report ID'),
              ),
              TextFormField(
                controller: _weatherNotesController,
                decoration: const InputDecoration(labelText: 'Weather Notes'),
              ),
              TextFormField(
                controller: _partnerCodeController,
                decoration: const InputDecoration(labelText: 'Referral Code'),
              ),
              const SizedBox(height: 20),
              if (_quickEnabled)
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/quickReport'),
                  child: const Text('Start Quick Report'),
                ),
              if (_quickEnabled) const SizedBox(height: 20),
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
