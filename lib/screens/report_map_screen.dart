import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/saved_report.dart';
import '../models/inspection_metadata.dart';
import 'report_preview_screen.dart';

class ReportMapScreen extends StatefulWidget {
  const ReportMapScreen({super.key});

  @override
  State<ReportMapScreen> createState() => _ReportMapScreenState();
}

class _ReportMapScreenState extends State<ReportMapScreen> {
  late Future<List<SavedReport>> _futureReports;
  final TextEditingController _inspectorController = TextEditingController();
  DateTimeRange? _dateRange;
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _futureReports = _loadReports();
  }

  Future<List<SavedReport>> _loadReports() async {
    final snap = await FirebaseFirestore.instance.collection('reports').get();
    return snap.docs
        .map((d) => SavedReport.fromMap(d.data(), d.id))
        .toList();
  }

  List<SavedReport> _applyFilters(List<SavedReport> reports) {
    return reports.where((r) {
      if (r.latitude == null || r.longitude == null) return false;
      if (_statusFilter == 'finalized' && !r.isFinalized) return false;
      if (_statusFilter == 'draft' && r.isFinalized) return false;
      if (_inspectorController.text.isNotEmpty) {
        final name = (r.inspectionMetadata['inspectorName'] ?? '').toString();
        if (!name
            .toLowerCase()
            .contains(_inspectorController.text.toLowerCase())) {
          return false;
        }
      }
      if (_dateRange != null) {
        final meta = InspectionMetadata.fromMap(r.inspectionMetadata);
        if (meta.inspectionDate.isBefore(_dateRange!.start) ||
            meta.inspectionDate.isAfter(_dateRange!.end)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _dateRange,
    );
    if (range != null) setState(() => _dateRange = range);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report Map')),
      body: FutureBuilder<List<SavedReport>>(
        future: _futureReports,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading reports'));
          }
          final filtered = _applyFilters(snapshot.data ?? []);
          if (filtered.isEmpty) {
            return const Center(child: Text('No reports found'));
          }
          final center =
              LatLng(filtered.first.latitude!, filtered.first.longitude!);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _inspectorController,
                      decoration: const InputDecoration(
                        labelText: 'Inspector',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _pickRange,
                            child: Text(_dateRange != null
                                ? '${_dateRange!.start.toLocal().toString().split(' ')[0]} - ${_dateRange!.end.toLocal().toString().split(' ')[0]}'
                                : 'Select Date Range'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        DropdownButton<String>(
                          value: _statusFilter,
                          onChanged: (val) {
                            if (val != null) setState(() => _statusFilter = val);
                          },
                          items: const [
                            DropdownMenuItem(
                                value: 'all', child: Text('All')),
                            DropdownMenuItem(
                                value: 'finalized', child: Text('Finalized')),
                            DropdownMenuItem(value: 'draft', child: Text('Draft')),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 0),
              Expanded(
                child: FlutterMap(
                  options: MapOptions(center: center, zoom: 12),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: ['a', 'b', 'c'],
                      userAgentPackageName: 'com.clearsky.app',
                    ),
                    MarkerLayer(
                      markers: [
                        for (final r in filtered)
                          Marker(
                            point: LatLng(r.latitude!, r.longitude!),
                            width: 40,
                            height: 40,
                            builder: (context) => GestureDetector(
                              onTap: () {
                                final meta = InspectionMetadata.fromMap(
                                    r.inspectionMetadata);
                                showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: Text(meta.propertyAddress),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Inspector: ${meta.inspectorName ?? ''}'),
                                        Text('Status: ${r.isFinalized ? 'finalized' : 'draft'}'),
                                        const SizedBox(height: 8),
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => ReportPreviewScreen(
                                                  metadata: meta,
                                                  structures: r.structures,
                                                  readOnly: true,
                                                  summary: r.summary,
                                                  savedReport: r,
                                                ),
                                              ),
                                            );
                                          },
                                          child: const Text('Open Report'),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              child: Semantics(
                                label: 'Report location',
                                button: true,
                                child: Icon(
                                  Icons.location_on,
                                  color: r.isFinalized ? Colors.green : Colors.orange,
                                  size: 40,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
