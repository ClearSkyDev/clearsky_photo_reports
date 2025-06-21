import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Builds a photo preview widget with an editable label field.
///
/// [aiSuggestion] is used to pre-fill the text field when provided.
Widget buildLabeledPhotoPreview(Uint8List photoData, String? aiSuggestion) {
  final labelController = TextEditingController(text: aiSuggestion ?? '');

  return Column(
    children: [
      Image.memory(photoData, height: 200),
      TextFormField(
        controller: labelController,
        decoration: const InputDecoration(
          labelText: 'Label this photo',
        ),
      ),
    ],
  );
}
