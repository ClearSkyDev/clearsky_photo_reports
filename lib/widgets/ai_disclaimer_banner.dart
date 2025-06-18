import 'package:flutter/material.dart';

/// Banner or tooltip showing AI disclaimer information.
class AiDisclaimerBanner extends StatelessWidget {
  final bool aiUsed;
  const AiDisclaimerBanner({super.key, this.aiUsed = true});

  static const String _aiText =
      'This report was generated using AI-assisted tools. Please verify that all findings, labels, and recommendations are accurate. ClearSky is not responsible for any inaccuracies. You, the user, are responsible for all submitted data.';
  static const String _manualText =
      'This report was manually labeled. No AI assistance was used.';

  void _showDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Report Notice'),
        content: Text(aiUsed ? _aiText : _manualText),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final label = aiUsed ? '⚠️ AI Assisted' : 'Manual Mode';
    return Tooltip(
      message: label,
      child: GestureDetector(
        onTap: () => _showDialog(context),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.orange.shade100,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning, color: Colors.orange, size: 16),
              const SizedBox(width: 4),
              Text(label, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
