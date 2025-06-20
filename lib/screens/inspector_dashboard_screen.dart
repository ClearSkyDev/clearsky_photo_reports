import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/saved_report.dart';
import '../models/inspection_metadata.dart';
import '../models/inspected_structure.dart';
import '../models/photo_entry.dart';
import '../models/checklist_template.dart' show InspectorReportRole;
import '../services/offline_draft_store.dart';
import '../services/offline_sync_service.dart';
import '../utils/profile_storage.dart';
import '../models/inspector_profile.dart';
import 'report_preview_screen.dart';
import 'send_report_screen.dart';

class InspectorDashboardScreen extends StatefulWidget {
  const InspectorDashboardScreen({super.key});

  @override
  State<InspectorDashboardScreen> createState() =>
      _InspectorDashboardScreenState();
}

class _InspectorDashboardScreenState extends State<InspectorDashboardScreen> {
  late Future<List<SavedReport>> _futureReports;
  final TextEditingController _searchController = TextEditingController();
  DateTimeRange? _range;
  String _statusFilter = 'all';
  InspectorReportRole? _roleFilter;

  @override
  void initState() {
    super.initState();
    _futureReports = _loadReports();
  }

  Future<List<SavedReport>> _loadReports() async {
    final firestore = FirebaseFirestore.instance;
    Query query =
        firestore.collection('reports').orderBy('createdAt', descending: true);
    final profile = await ProfileStorage.load();
    if (profile != null && profile.role != InspectorRole.admin) {
      query = query.where('inspectionMetadata.inspectorName',
          isEqualTo: profile.name);
    }
    final snap = await query.get();
    final remote = snap.docs
        .map((d) => SavedReport.fromMap(d.data() as Map<String, dynamic>, d.id))
        .toList();
    final local = OfflineDraftStore.instance.loadReports();
    return [...local, ...remote];
  }

  void _pickDateRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _range,
    );
    if (range != null) setState(() => _range = range);
  }

  List<SavedReport> _applyFilters(List<SavedReport> reports) {
    final query = _searchController.text.toLowerCase();
    return reports.where((r) {
      final meta = InspectionMetadata.fromMap(r.inspectionMetadata);
      if (query.isNotEmpty) {
        final name = meta.clientName.toLowerCase();
        final addr = meta.propertyAddress.toLowerCase();
        final date = meta.inspectionDate.toLocal().toString().split(' ')[0];
        if (!name.contains(query) &&
            !addr.contains(query) &&
            !date.contains(query)) {
          return false;
        }
      }
      if (_range != null) {
        if (meta.inspectionDate.isBefore(_range!.start) ||
            meta.inspectionDate.isAfter(_range!.end)) {
          return false;
        }
      }
      if (_roleFilter != null && !meta.inspectorRoles.contains(_roleFilter))
        return false;
      if (_statusFilter == 'draft' && r.isFinalized) return false;
      if (_statusFilter == 'final' && !r.isFinalized) return false;
      if (_statusFilter == 'shared' && r.publicViewLink == null) return false;
      return true;
    }).toList();
  }

  void _sync() async {
    await OfflineSyncService.instance.syncDrafts();
    if (mounted) setState(() => _futureReports = _loadReports());
  }

  Widget _buildCard(SavedReport report) {
    final meta = InspectionMetadata.fromMap(report.inspectionMetadata);
    final date = meta.inspectionDate.toLocal().toString().split(' ')[0];
    final statusIcon = report.localOnly ? Icons.cloud_off : Icons.cloud_done;
    final statusColor = report.localOnly ? Colors.red : Colors.green;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Icon(statusIcon, color: statusColor),
        title: Text(meta.propertyAddress),
        subtitle: Text('${meta.clientName} • $date'),
        trailing: Wrap(
          spacing: 4,
          children: [
            IconButton(
              icon: const Icon(Icons.visibility),
              tooltip: 'View',
              onPressed: () {
                final structs = <InspectedStructure>[];
                for (final s in report.structures) {
                  final map = <String, List<PhotoEntry>>{};
                  s.sectionPhotos.forEach((k, v) {
                    map[k] = v
                        .map((e) => PhotoEntry(
                              url: e.photoUrl,
                              label: e.label,
                              damageType: e.damageType,
                              capturedAt: e.timestamp ?? DateTime.now(),
                              latitude: e.latitude,
                              longitude: e.longitude,
                              note: e.note,
                            ))
                        .toList();
                  });
                  structs.add(InspectedStructure(
                    name: s.name,
                    sectionPhotos: map as Map<
                        String,
                        List<
                            ReportPhotoEntry>>, // ignore: cast_nullable_to_non_nullable
                    slopeTestSquare: Map.from(s.slopeTestSquare),
                  ));
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReportPreviewScreen(
                      metadata: meta,
                      structures: structs,
                      readOnly: true,
                      summary: report.summary,
                      savedReport: report,
                    ),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit',
              onPressed: () {
                final structs = <InspectedStructure>[];
                for (final s in report.structures) {
                  final map = <String, List<PhotoEntry>>{};
                  s.sectionPhotos.forEach((k, v) {
                    map[k] = v
                        .map((e) => PhotoEntry(
                              url: e.photoUrl,
                              label: e.label,
                              damageType: e.damageType,
                              capturedAt: e.timestamp ?? DateTime.now(),
                              latitude: e.latitude,
                              longitude: e.longitude,
                              note: e.note,
                            ))
                        .toList();
                  });
                  structs.add(InspectedStructure(
                    name: s.name,
                    sectionPhotos: map as Map<
                        String,
                        List<
                            ReportPhotoEntry>>, // ignore: cast_nullable_to_non_nullable
                    slopeTestSquare: Map.from(s.slopeTestSquare),
                  ));
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReportPreviewScreen(
                      metadata: meta,
                      structures: structs,
                      readOnly: false,
                      summary: report.summary,
                      savedReport: report,
                    ),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: 'Share',
              onPressed: () {
                final structs = <InspectedStructure>[];
                for (final s in report.structures) {
                  final map = <String, List<PhotoEntry>>{};
                  s.sectionPhotos.forEach((k, v) {
                    map[k] = v
                        .map((e) => PhotoEntry(
                              url: e.photoUrl,
                              label: e.label,
                              damageType: e.damageType,
                              capturedAt: e.timestamp ?? DateTime.now(),
                              latitude: e.latitude,
                              longitude: e.longitude,
                              note: e.note,
                            ))
                        .toList();
                  });
                  structs.add(InspectedStructure(
                    name: s.name,
                    sectionPhotos: map as Map<
                        String,
                        List<
                            ReportPhotoEntry>>, // ignore: cast_nullable_to_non_nullable
                    slopeTestSquare: Map.from(s.slopeTestSquare),
                  ));
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SendReportScreen(
                      metadata: meta,
                      structures: structs,
                      summary: report.summary,
                      summaryText: report.summaryText,
                      signature: null,
                      template: null,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inspector Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_sync),
            tooltip: 'Sync Drafts',
            onPressed: _sync,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Refresh',
            onPressed: () => setState(() => _futureReports = _loadReports()),
          ),
        ],
      ),
      body: FutureBuilder<List<SavedReport>>(
        future: _futureReports,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final filtered = _applyFilters(snapshot.data!);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        labelText: 'Search',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _pickDateRange,
                            child: Text(_range != null
                                ? '${_range!.start.toLocal().toString().split(' ')[0]} - ${_range!.end.toLocal().toString().split(' ')[0]}'
                                : 'Select Date Range'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        DropdownButton<String>(
                          value: _statusFilter,
                          onChanged: (val) {
                            if (val != null)
                              setState(() => _statusFilter = val);
                          },
                          items: const [
                            DropdownMenuItem(value: 'all', child: Text('All')),
                            DropdownMenuItem(
                                value: 'draft', child: Text('Draft')),
                            DropdownMenuItem(
                                value: 'final', child: Text('Final')),
                            DropdownMenuItem(
                                value: 'shared', child: Text('Shared')),
                          ],
                        ),
                        const SizedBox(width: 8),
                        DropdownButton<InspectorReportRole?>(
                          value: _roleFilter,
                          hint: const Text('Role'),
                          onChanged: (val) {
                            setState(() => _roleFilter = val);
                          },
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Any'),
                            ),
                            ...InspectorReportRole.values.map(
                              (r) => DropdownMenuItem(
                                value: r,
                                child: Text(r.name),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 0),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('No matching reports'))
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, i) => _buildCard(filtered[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
