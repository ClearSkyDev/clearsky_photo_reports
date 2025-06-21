import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/color_extensions.dart';

import '../../core/models/report_theme.dart';

class ReportThemeScreen extends StatefulWidget {
  const ReportThemeScreen({super.key});

  @override
  State<ReportThemeScreen> createState() => _ReportThemeScreenState();
}

class _ReportThemeScreenState extends State<ReportThemeScreen> {
  final ImagePicker _picker = ImagePicker();
  String? _logoPath;
  String _selectedColor = 'Blue';
  String _selectedFont = 'Arial';

  static const Map<String, MaterialColor> _colors = {
    'Blue': Colors.blue,
    'Red': Colors.red,
    'Green': Colors.green,
    'Orange': Colors.orange,
    'Purple': Colors.purple,
  };

  static const List<String> _fonts = [
    'Arial',
    'Helvetica',
    'Times',
    'Courier',
  ];

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('report_theme');
    if (data != null) {
      final map = jsonDecode(data) as Map<String, dynamic>;
      final theme = ReportTheme.fromMap(map);
      setState(() {
        _logoPath = theme.logoPath;
        _selectedColor = _colors.entries
            .firstWhere((e) => e.value.toArgb() == theme.primaryColor,
                orElse: () => const MapEntry('Blue', Colors.blue))
            .key;
        if (_fonts.contains(theme.fontFamily)) {
          _selectedFont = theme.fontFamily;
        }
      });
    }
  }

  Future<void> _pickLogo() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _logoPath = image.path;
      });
    }
  }

  Future<void> _saveTheme() async {
    final theme = ReportTheme(
      name: 'custom',
      primaryColor: _colors[_selectedColor]!.toArgb(),
      fontFamily: _selectedFont,
      logoPath: _logoPath,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('report_theme', jsonEncode(theme.toMap()));
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Theme saved')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final previewColor = _colors[_selectedColor]!;
    return Scaffold(
      appBar: AppBar(title: const Text('Report Theme')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
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
              value: _selectedFont,
              decoration: const InputDecoration(labelText: 'Font'),
              items: _fonts
                  .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedFont = val);
                }
              },
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: previewColor),
              ),
              child: Column(
                children: [
                  if (_logoPath != null) Image.network(_logoPath!, height: 80),
                  Text(
                    'Section Header',
                    style: TextStyle(
                      color: previewColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: _selectedFont,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Body text preview showing the chosen font and color.',
                    style: TextStyle(fontFamily: _selectedFont),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveTheme,
              child: const Text('Save Theme'),
            ),
          ],
        ),
      ),
    );
  }
}
