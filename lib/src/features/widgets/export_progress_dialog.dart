import 'package:flutter/material.dart';

class ExportProgressDialog extends StatelessWidget {
  const ExportProgressDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return const AlertDialog(
      content: SizedBox(
        height: 60,
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
