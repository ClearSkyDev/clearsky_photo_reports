import 'package:flutter/material.dart';
import '../../app/app_theme.dart';

/// A collapsible tile with take photo and gallery actions.
class ExpandableTile extends StatefulWidget {
  final String title;
  final VoidCallback onTakePhoto;
  final VoidCallback onChooseGallery;
  final bool isCompleted;

  const ExpandableTile({
    super.key,
    required this.title,
    required this.onTakePhoto,
    required this.onChooseGallery,
    required this.isCompleted,
  });

  @override
  State<ExpandableTile> createState() => _ExpandableTileState();
}

class _ExpandableTileState extends State<ExpandableTile> {
  bool _expanded = false;

  void _toggle() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        children: [
          ListTile(
            title: Text(widget.title),
            onTap: _toggle,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.isCompleted)
                  const Icon(Icons.check_circle, color: Colors.green),
                Icon(_expanded ? Icons.expand_less : Icons.expand_more),
              ],
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: widget.onTakePhoto,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Take Photo'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: widget.onChooseGallery,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Choose from Gallery'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.clearSkyTheme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
