import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/models/inspection_report.dart';

class ReportSearchScreen extends StatefulWidget {
  final List<InspectionReport> allReports;

  const ReportSearchScreen({super.key, required this.allReports});

  @override
  ReportSearchScreenState createState() => ReportSearchScreenState();
}

class ReportSearchScreenState extends State<ReportSearchScreen> {
  List<InspectionReport> _filteredReports = [];
  String _searchQuery = '';

  void _updateSearch(String value) {
    if (!mounted) return;
    setState(() {
      _searchQuery = value.toLowerCase().trim();
      _filteredReports = widget.allReports.where((report) {
        final title = (report.title ?? '').toLowerCase();
        final address = (report.address ?? '').toLowerCase();
        final date = DateFormat.yMd().format(report.date);
        return title.contains(_searchQuery) ||
            address.contains(_searchQuery) ||
            date.contains(_searchQuery);
      }).toList();
    });
  }

  void _openReport(InspectionReport report) {
    // Navigate to report detail or editor screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Open report: ${report.title ?? 'Untitled'}')),
    );
  }

  @override
  void initState() {
    super.initState();
    _filteredReports = widget.allReports;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Reports'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: _updateSearch,
              decoration: const InputDecoration(
                labelText: 'Search by title, address, or date',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: _filteredReports.isEmpty
                ? const Center(child: Text('No matching reports found.'))
                : ListView.builder(
                    itemCount: _filteredReports.length,
                    itemBuilder: (context, index) {
                      final report = _filteredReports[index];
                      return ListTile(
                        title: Text(report.title ?? 'Untitled Report'),
                        subtitle: Text(report.address ?? 'No address'),
                        trailing: Text(DateFormat.yMMMd().format(report.date)),
                        onTap: () => _openReport(report),
                      );
                    },
                  ),
          )
        ],
      ),
    );
  }
}
