import 'package:flutter/material.dart';
import '../../core/models/inspection_report.dart'; // Make sure this exists
import 'inspection_detail_screen.dart';
import '../screens/inspection_checklist_screen.dart';

class ClientDashboardScreen extends StatefulWidget {
  const ClientDashboardScreen({super.key});

  @override
  ClientDashboardScreenState createState() => ClientDashboardScreenState();
}

class ClientDashboardScreenState extends State<ClientDashboardScreen> {
  final List<InspectionReport> _allReports = []; // Your reports list
  String _filter = 'All'; // Filter: All, Synced, Unsynced

  void _openReport(InspectionReport report) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InspectionDetailScreen(report: report),
      ),
    );
  }

  void _deleteReport(int index) {
    setState(() {
      _allReports.removeAt(index);
    });
  }

  void _syncReport(InspectionReport report) {
    setState(() {
      report.synced = true;
    });
  }

  void _createNewInspection() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const InspectionChecklistScreen(),
      ),
    );
  }

  List<InspectionReport> get _filteredReports {
    if (_filter == 'Synced') {
      return _allReports.where((r) => r.synced).toList();
    } else if (_filter == 'Unsynced') {
      return _allReports.where((r) => !r.synced).toList();
    }
    return _allReports;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Inspections'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _filter = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'All', child: Text('All')),
              const PopupMenuItem(value: 'Synced', child: Text('Synced Only')),
              const PopupMenuItem(value: 'Unsynced', child: Text('Unsynced Only')),
            ],
          )
        ],
      ),
      body: _filteredReports.isEmpty
          ? const Center(child: Text('No reports found.'))
          : ListView.builder(
              itemCount: _filteredReports.length,
              itemBuilder: (context, index) {
                final report = _filteredReports[index];
                return ListTile(
                  title: Text(report.title ?? 'Untitled Report'),
                  subtitle: Text(report.synced ? 'Synced' : 'Unsynced'),
                  onTap: () => _openReport(report),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!report.synced)
                        IconButton(
                          icon: const Icon(Icons.cloud_upload),
                          onPressed: () => _syncReport(report),
                        ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteReport(index),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewInspection,
        tooltip: 'New Inspection',
        child: const Icon(Icons.add),
      ),
    );
  }
}
