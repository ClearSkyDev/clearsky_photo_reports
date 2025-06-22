import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/models/saved_report.dart';
import '../../core/models/inspection_metadata.dart';
import '../../core/models/inspection_type.dart';
import '../../core/models/photo_entry.dart';
import '../../core/models/inspected_structure.dart';
import '../../core/models/peril_type.dart';
import 'report_preview_screen.dart';
import 'message_thread_screen.dart';
import '../../core/utils/template_store.dart';
import '../../core/models/report_template.dart';
import 'metadata_screen.dart';
import '../../core/services/offline_draft_store.dart';
import '../../core/services/offline_sync_service.dart';

class ReportHistoryScreen extends StatefulWidget {
  final String? inspectorName;
  const ReportHistoryScreen({super.key, this.inspectorName});

  @override
  State<ReportHistoryScreen> createState() => _ReportHistoryScreenState();
}

class _ReportHistoryScreenState extends State<ReportHistoryScreen> {
  late Future<List<SavedReport>> _futureReports;
  final TextEditingController _searchController = TextEditingController();
  DateTimeRange? _selectedRange;
  bool _sortDescending = true;
  final Set<PerilType> _selectedPerils = {};
  final Set<InspectionType> _selectedTypes = {};
  String _statusFilter = 'all';
  bool _withAttachments = false;

  @override
  void initState() {
    super.initState();
    _futureReports = _loadReports();
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _selectedRange,
    );
    if (range != null) {
      if (!mounted) return;
      setState(() {
        _selectedRange = range;
      });
    }
  }

  List<SavedReport> _applyFilters(List<SavedReport> reports) {
    final query = _searchController.text.toLowerCase();
    final start = _selectedRange?.start;
    final end = _selectedRange?.end;

    final filtered = reports.where((r) {
      final meta = InspectionMetadata.fromMap(r.inspectionMetadata);
      if (query.isNotEmpty) {
        final matchClient = meta.clientName.toLowerCase().contains(query);
        final matchAddress = meta.propertyAddress.toLowerCase().contains(query);
        if (!matchClient && !matchAddress) return false;
      }
      if (start != null && end != null) {
        if (meta.inspectionDate.isBefore(start) ||
            meta.inspectionDate.isAfter(end)) {
          return false;
        }
      }
      if (_selectedPerils.isNotEmpty &&
          !_selectedPerils.contains(meta.perilType)) {
        return false;
      }
      if (_selectedTypes.isNotEmpty &&
          !_selectedTypes.contains(meta.inspectionType)) {
        return false;
      }
      if (_statusFilter == 'finalized' && !r.isFinalized) return false;
      if (_statusFilter == 'draft' && r.isFinalized) return false;
      if (_withAttachments && r.attachments.isEmpty) return false;
      return true;
    }).toList();

    filtered.sort((a, b) {
      final cmp = a.createdAt.compareTo(b.createdAt);
      return _sortDescending ? -cmp : cmp;
    });
    return filtered;
  }

  Future<List<SavedReport>> _loadReports() async {
    final firestore = FirebaseFirestore.instance;
    Query query =
        firestore.collection('reports').orderBy('createdAt', descending: true);
    String? inspector = widget.inspectorName;
    if (inspector != null && inspector.isNotEmpty) {
      query =
          query.where('inspectionMetadata.inspectorName', isEqualTo: inspector);
    }
    final snapshot = await query.get();
    final remote = snapshot.docs
        .map((doc) =>
            SavedReport.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
    final local = OfflineDraftStore.instance.loadReports();
    return [...local, ...remote];
  }

  Widget _buildTile(SavedReport report) {
    final meta = InspectionMetadata.fromMap(report.inspectionMetadata);
    String date = meta.inspectionDate.toLocal().toString().split(' ')[0];
    String status = report.isFinalized ? 'Final' : 'Draft';
    String subtitle = '${meta.clientName} • $date • $status v${report.version}';
    String? thumbUrl;
    for (var struct in report.structures) {
      for (var photos in struct.sectionPhotos.values) {
        if (photos.isNotEmpty) {
          thumbUrl = photos.first.photoUrl;
          break;
        }
      }
      if (thumbUrl != null) break;
    }
    return ListTile(
      leading: thumbUrl != null
          ? Image.network(thumbUrl, width: 56, height: 56, fit: BoxFit.cover)
          : const Icon(Icons.description),
      title: Text(meta.propertyAddress),
      subtitle: Text(subtitle),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ValueListenableBuilder<double>(
            valueListenable: OfflineSyncService.instance.progress,
            builder: (context, prog, _) {
              if (report.localOnly && prog > 0 && prog < 1) {
                return const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              }
              return Icon(
                report.localOnly ? Icons.cloud_off : Icons.cloud_done,
                color: report.localOnly ? Colors.red : Colors.green,
                size: 20,
              );
            },
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.chat),
            tooltip: 'Open Messages',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MessageThreadScreen(
                    reportId: report.id,
                    inspectorView: true,
                    threadTitle: '',
                    currentUserId: '',
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Duplicate',
            onPressed: () async {
              final meta =
                  InspectionMetadata.fromMap(report.inspectionMetadata);
              ReportTemplate? template;
              if (report.templateId != null) {
                final templates = await TemplateStore.loadTemplates();
                try {
                  template =
                      templates.firstWhere((t) => t.id == report.templateId);
                } catch (_) {}
              }
              if (!mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MetadataScreen(
                    initialMetadata: meta,
                    initialTemplate: template,
                  ),
                ),
              );
            },
          ),
          if (report.isFinalized) const Icon(Icons.lock, color: Colors.red),
        ],
      ),
      onTap: () {
        final structs = <InspectedStructure>[];
        for (var s in report.structures) {
          final sections = <String, List<PhotoEntry>>{};
          s.sectionPhotos.forEach((key, value) {
            sections[key] = value
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
            sectionPhotos: sections.map((key, value) => MapEntry(
                  key,
                  value
                      .map((e) => ReportPhotoEntry(
                            photoUrl: e.url,
                            label: e.label,
                            damageType: e.damageType,
                            timestamp: e.capturedAt,
                            latitude: e.latitude,
                            longitude: e.longitude,
                            note: e.note,
                          ))
                      .toList(),
                )),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report History')),
      body: FutureBuilder<List<SavedReport>>(
        future: _futureReports,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading reports'));
          }
          final reports = snapshot.data ?? [];
          if (reports.isEmpty) {
            return const Center(child: Text('No reports found'));
          }

          final filtered = _applyFilters(reports);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
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
                            child: Text(_selectedRange != null
                                ? '${_selectedRange!.start.toLocal().toString().split(' ')[0]} - ${_selectedRange!.end.toLocal().toString().split(' ')[0]}'
                                : 'Select Date Range'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        DropdownButton<String>(
                          value: _sortDescending ? 'newest' : 'oldest',
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _sortDescending = val == 'newest';
                              });
                            }
                          },
                          items: [
                            const DropdownMenuItem(
                                value: 'newest', child: Text('Newest')),
                            const DropdownMenuItem(
                                value: 'oldest', child: Text('Oldest')),
                          ],
                        ),
                        const SizedBox(width: 8),
                        DropdownButton<String>(
                          value: _statusFilter,
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _statusFilter = val);
                            }
                          },
                          items: [
                            const DropdownMenuItem(value: 'all', child: Text('All')),
                            const DropdownMenuItem(
                                value: 'finalized', child: Text('Finalized')),
                            const DropdownMenuItem(
                                value: 'draft', child: Text('Draft')),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      children: PerilType.values
                          .map(
                            (p) => FilterChip(
                              label: Text(p.name),
                              selected: _selectedPerils.contains(p),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedPerils.add(p);
                                  } else {
                                    _selectedPerils.remove(p);
                                  }
                                });
                              },
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      children: InspectionType.values
                          .map(
                            (t) => FilterChip(
                              label: Text(t.name),
                              selected: _selectedTypes.contains(t),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedTypes.add(t);
                                  } else {
                                    _selectedTypes.remove(t);
                                  }
                                });
                              },
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 8),
                    FilterChip(
                      label: const Text('Attachments'),
                      selected: _withAttachments,
                      onSelected: (val) {
                        setState(() => _withAttachments = val);
                      },
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
                        itemBuilder: (context, index) =>
                            _buildTile(filtered[index]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
