import 'package:flutter/material.dart';
import '../models/inspection_report.dart';
import 'report_preview_screen.dart';

class ClientDashboardScreen extends StatefulWidget {
  const ClientDashboardScreen({super.key});

  @override
  State<ClientDashboardScreen> createState() => _ClientDashboardScreenState();
}

class _ClientDashboardScreenState extends State<ClientDashboardScreen> {
  final List<InspectionReport> _allReports = [
    InspectionReport(
      jobName: 'Johnson Residence',
      address: '123 Main St, Dallas TX',
      date: DateTime(2025, 6, 15),
      synced: true,
    ),
    InspectionReport(
      jobName: 'Smith Roof Claim',
      address: '44 Elm St, Austin TX',
      date: DateTime(2025, 6, 10),
      synced: false,
    ),
  ];

  String _searchQuery = '';
  String _filter = 'All';

  List<InspectionReport> get _filteredReports {
    return _allReports.where((report) {
      final matchesSearch = report.jobName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          report.address.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesFilter = _filter == 'All' ||
          (_filter == 'Synced' && report.synced) ||
          (_filter == 'Unsynced' && !report.synced);

      return matchesSearch && matchesFilter;
    }).toList();
  }

  void _openReport(InspectionReport report) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportPreviewScreen(photos: report.photos),
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
    // TODO: Navigate to inspection setup screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('New Inspection button tapped')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Inspections'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() => _filter = value);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'All', child: Text('All')),
              PopupMenuItem(value: 'Synced', child: Text('Synced Only')),
              PopupMenuItem(value: 'Unsynced', child: Text('Unsynced Only')),
            ],
            icon: const Icon(Icons.filter_list),
          )
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search by job name or address',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
        ),
      ),
      body: _filteredReports.isEmpty
          ? const Center(child: Text('No inspections found.'))
          : ListView.builder(
              itemCount: _filteredReports.length,
              itemBuilder: (context, index) {
                final report = _filteredReports[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text(report.jobName),
                    subtitle: Text(
                      '${report.address}\n${report.date.toLocal().toString().split(' ')[0]}',
                    ),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'View':
                            _openReport(report);
                            break;
                          case 'Delete':
                            final i = _allReports.indexOf(report);
                            _deleteReport(i);
                            break;
                          case 'Sync':
                            _syncReport(report);
                            break;
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'View', child: Text('View Report')),
                        PopupMenuItem(value: 'Sync', child: Text('Sync to Cloud')),
                        PopupMenuItem(value: 'Delete', child: Text('Delete')),
                      ],
                    ),
                    leading: Icon(
                      report.synced ? Icons.cloud_done : Icons.cloud_upload,
                      color: report.synced ? Colors.green : Colors.grey,
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewInspection,
        icon: const Icon(Icons.add),
        label: const Text('New Inspection'),
      ),
    );
  }
}
