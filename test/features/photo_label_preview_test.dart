import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clearsky_photo_reports/src/features/widgets/photo_label_preview.dart';
import '../firebase_test_setup.dart';

void main() {
  setUpAll(() async {
    await setupFirebase();
  });
  testWidgets('AI suggestion populates text field', (WidgetTester tester) async {
    const base64Image = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAAAAAA6fptVAAAADElEQVR4nGNgYAAAAAMAASsJTYQAAAAASUVORK5CYII=';
    final bytes = base64Decode(base64Image);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: buildLabeledPhotoPreview(bytes, 'Hail damage'),
        ),
      ),
    );

    expect(find.text('Hail damage'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);
  });
}
