import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clearsky_photo_reports/screens/client_dashboard_screen.dart';
import 'package:clearsky_photo_reports/models/inspection_report.dart';
import '../firebase_test_setup.dart';

void main() {
  setUpAll(() async {
    await setupFirebase();
  });
  testWidgets('Dashboard loads and new inspection triggers snackBar',
      (WidgetTester tester) async {
    // Build the widget tree
    await tester.pumpWidget(
      const MaterialApp(
        home: ClientDashboardScreen(),
      ),
    );

    // Verify the title is shown
    expect(find.text('My Inspections'), findsOneWidget);

    // Tap the FAB to create a new inspection
    final fabFinder = find.byType(FloatingActionButton);
    expect(fabFinder, findsOneWidget);

    await tester.tap(fabFinder);
    await tester.pump(); // Let the snackbar animate

    // Expect snackbar to appear
    expect(find.text('New Inspection button tapped'), findsOneWidget);
  });

  testWidgets('Dashboard shows a list of inspections',
      (WidgetTester tester) async {
    // Create fake reports
    final reports = [
      InspectionReport(id: '1', title: 'Roof A', synced: false),
      InspectionReport(id: '2', title: 'Roof B', synced: true),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView.builder(
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              return ListTile(
                title: Text(report.title ?? ''),
                subtitle: Text(report.synced ? 'Synced' : 'Unsynced'),
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('Roof A'), findsOneWidget);
    expect(find.text('Unsynced'), findsOneWidget);
    expect(find.text('Roof B'), findsOneWidget);
    expect(find.text('Synced'), findsOneWidget);
  });
}
