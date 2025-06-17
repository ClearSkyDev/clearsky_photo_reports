import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/sync_preferences.dart';

class ReportSettings {
  final String companyName;
  final String tagline;
  final String? logoPath;
  final int primaryColor;
  final bool includeDisclaimer;
  final bool showGpsData;
  final bool autoLegalBackup;
  final String footerText;
  final String template;
  final String emailMessage;
  final String emailSignature;
  final bool attachPdf;

  ReportSettings({
    required this.companyName,
    required this.tagline,
    this.logoPath,
    required this.primaryColor,
    required this.includeDisclaimer,
    required this.showGpsData,
    this.autoLegalBackup = false,
    required this.footerText,
    required this.template,
    this.emailMessage = '',
    this.emailSignature = '',
    this.attachPdf = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'companyName': companyName,
      'tagline': tagline,
      if (logoPath != null) 'logoPath': logoPath,
      'primaryColor': primaryColor,
      'includeDisclaimer': includeDisclaimer,
      'showGpsData': showGpsData,
      'autoLegalBackup': autoLegalBackup,
      'footerText': footerText,
      'template': template,
      'emailMessage': emailMessage,
      'emailSignature': emailSignature,
      'attachPdf': attachPdf,
    };
  }

  factory ReportSettings.fromMap(Map<String, dynamic> map) {
    return ReportSettings(
      companyName: map['companyName'] ?? '',
      tagline: map['tagline'] ?? '',
      logoPath: map['logoPath'] as String?,
      primaryColor: map['primaryColor'] is int
          ? map['primaryColor'] as int
          : int.tryParse(map['primaryColor']?.toString() ?? '') ?? 0xff2196f3,
      includeDisclaimer: map['includeDisclaimer'] as bool? ?? true,
      showGpsData: map['showGpsData'] as bool? ?? true,
      autoLegalBackup: map['autoLegalBackup'] as bool? ?? false,
      footerText: map['footerText'] ?? '',
      template: map['template'] ?? 'legacy',
      emailMessage: map['emailMessage'] ?? '',
      emailSignature: map['emailSignature'] ?? '',
      attachPdf: map['attachPdf'] as bool? ?? true,
    );
  }
}

class ReportSettingsScreen extends StatefulWidget {
  const ReportSettingsScreen({super.key});

  @override
  State<ReportSettingsScreen> createState() => _ReportSettingsScreenState();
}

class _ReportSettingsScreenState extends State<ReportSettingsScreen> {
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _taglineController = TextEditingController();
  final TextEditingController _footerController = TextEditingController();
  final TextEditingController _emailMessageController = TextEditingController();
  final TextEditingController _signatureController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  String? _logoPath;
  bool _includeDisclaimer = true;
  bool _showGpsData = true;
  bool _autoLegalBackup = false;
  bool _cloudSyncEnabled = true;
  bool _attachPdf = true;

  static const Map<String, MaterialColor> _colors = {
    'Blue': Colors.blue,
    'Red': Colors.red,
    'Green': Colors.green,
    'Orange': Colors.orange,
    'Purple': Colors.purple,
  };
  String _selectedColor = 'Blue';
  static const Map<String, String> _templates = {
    'Legacy Style': 'legacy',
    'Clean & Simple': 'clean',
    'Modern + Colored Section Headers': 'modern',
  };
  String _selectedTemplate = 'legacy';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _pickLogo() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _logoPath = image.path;
      });
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('report_settings');
    if (data != null) {
      final map = jsonDecode(data) as Map<String, dynamic>;
      final settings = ReportSettings.fromMap(map);
      setState(() {
        _companyController.text = settings.companyName;
        _taglineController.text = settings.tagline;
        _footerController.text = settings.footerText;
        _logoPath = settings.logoPath;
        _selectedColor = _colors.entries
                .firstWhere(
                    (e) => e.value.value == settings.primaryColor,
                    orElse: () => const MapEntry('Blue', Colors.blue))
                .key;
        _includeDisclaimer = settings.includeDisclaimer;
        _showGpsData = settings.showGpsData;
        _autoLegalBackup = settings.autoLegalBackup;
        _emailMessageController.text = settings.emailMessage;
        _signatureController.text = settings.emailSignature;
        _attachPdf = settings.attachPdf;
        _selectedTemplate = _templates.entries
                .firstWhere(
                    (e) => e.value == settings.template,
                    orElse: () => const MapEntry('Legacy Style', 'legacy'))
                .key;
      });
    }
    _cloudSyncEnabled = await SyncPreferences.isCloudSyncEnabled();
  }

  Future<void> _saveSettings() async {
    final settings = ReportSettings(
      companyName: _companyController.text.trim(),
      tagline: _taglineController.text.trim(),
      logoPath: _logoPath,
      primaryColor: _colors[_selectedColor]!.value,
      includeDisclaimer: _includeDisclaimer,
      showGpsData: _showGpsData,
      autoLegalBackup: _autoLegalBackup,
      footerText: _footerController.text.trim(),
      template: _templates[_selectedTemplate]!,
      emailMessage: _emailMessageController.text.trim(),
      emailSignature: _signatureController.text.trim(),
      attachPdf: _attachPdf,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('report_settings', jsonEncode(settings.toMap()));
    await SyncPreferences.setCloudSyncEnabled(_cloudSyncEnabled);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: _companyController,
              decoration: const InputDecoration(labelText: 'Company Name'),
            ),
            TextField(
              controller: _taglineController,
              decoration: const InputDecoration(labelText: 'Tagline'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _pickLogo,
                  icon: const Icon(Icons.image),
                  label: const Text('Upload Logo'),
                ),
                const SizedBox(width: 12),
                if (_logoPath != null)
                  Expanded(
                    child: Image.network(
                      _logoPath!,
                      height: 50,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedColor,
              decoration: const InputDecoration(labelText: 'Primary Color'),
              items: _colors.keys
                  .map((name) => DropdownMenuItem(
                        value: name,
                        child: Text(name),
                      ))
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedColor = val;
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedTemplate,
              decoration: const InputDecoration(labelText: 'Report Template'),
              items: _templates.keys
                  .map((name) => DropdownMenuItem(
                        value: name,
                        child: Text(name),
                      ))
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedTemplate = val;
                  });
                }
              },
            ),
            SwitchListTile(
              title: const Text('Include Disclaimer'),
              value: _includeDisclaimer,
              onChanged: (val) {
                setState(() {
                  _includeDisclaimer = val;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Show GPS on Photos'),
              value: _showGpsData,
              onChanged: (val) {
                setState(() {
                  _showGpsData = val;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Auto Backup Legal Copy'),
              value: _autoLegalBackup,
              onChanged: (val) {
                setState(() {
                  _autoLegalBackup = val;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Enable Cloud Sync'),
              value: _cloudSyncEnabled,
              onChanged: (val) {
                setState(() {
                  _cloudSyncEnabled = val;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Attach PDF to Email'),
              value: _attachPdf,
              onChanged: (val) {
                setState(() {
                  _attachPdf = val;
                });
              },
            ),
            TextField(
              controller: _emailMessageController,
              decoration:
                  const InputDecoration(labelText: 'Default Email Message'),
              maxLines: 3,
            ),
            TextField(
              controller: _signatureController,
              decoration: const InputDecoration(labelText: 'Email Signature'),
              maxLines: 3,
            ),
            TextField(
              controller: _footerController,
              decoration:
                  const InputDecoration(labelText: 'Custom Footer Text'),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveSettings,
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
