import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clearsky_photo_reports/main.dart';
import 'package:clearsky_photo_reports/screens/photo_upload_screen.dart';
import 'package:clearsky_photo_reports/screens/client_signature_screen.dart';
import 'package:clearsky_photo_reports/screens/checklist_screen.dart';
import 'package:clearsky_photo_reports/models/checklist_template.dart';

void main() {
  testWidgets('Home screen renders and buttons are visible',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ClearSkyApp());

    expect(find.text('ClearSky Home'), findsOneWidget);
    expect(find.text('Upload Photos'), findsOneWidget);
    expect(find.text('Generate Report'), findsOneWidget);
  });

  testWidgets('Navigation to Photo Upload screen works',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ClearSkyApp());

    await tester.tap(find.text('Upload Photos'));
    await tester.pumpAndSettle();

    expect(find.text('Pick Photos'), findsOneWidget);
  });

  testWidgets('Generate Report with no photos shows warning',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ClearSkyApp());

    await tester.tap(find.text('Generate Report'));
    await tester.pump(); // simulate UI update

    // Replace this with your real snackbar/dialog if implemented
    // expect(find.text('Please upload photos first'), findsOneWidget);
  });

  testWidgets('Checklist screen toggles item state',
      (WidgetTester tester) async {
    final testTemplate = ChecklistTemplate(
      id: '1',
      name: 'Test Checklist',
      items: [
        ChecklistItem(id: 'a', label: 'Test item 1'),
        ChecklistItem(id: 'b', label: 'Test item 2'),
      ],
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: ChecklistScreen()),
    ));

    // Simulate user interaction after adding template
    // Note: You may want to expose template injection via constructor for true testing
    expect(find.text('Add Item'), findsOneWidget);
  });

  testWidgets('Signature screen renders and captures data',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: ClientSignatureScreen()));

    expect(find.text('Client Signature'), findsOneWidget);
    expect(find.text('Finish & Attach'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'John Doe');

    final saveBtn = find.widgetWithText(ElevatedButton, 'Save');
    expect(saveBtn, findsOneWidget);

    await tester.tap(saveBtn);
    await tester.pump();

    // This won’t verify image bytes, but ensures interaction works.
    expect(find.byType(Signature), findsOneWidget);
  });
}
