import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/saved_report.dart';
import '../models/inspection_metadata.dart';
import '../models/photo_entry.dart';
import 'report_preview_screen.dart';
import '../utils/profile_storage.dart';
import '../models/inspector_profile.dart';

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
      if (_selectedPerils.isNotEmpty && !_selectedPerils.contains(meta.perilType)) {
        return false;
      }
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
    Query query = firestore
        .collection('reports')
        .orderBy('createdAt', descending: true);
    String? inspector = widget.inspectorName;
    if (inspector == null) {
      final profile = await ProfileStorage.load();
      if (profile != null && profile.role != InspectorRole.admin) {
        inspector = profile.name;
      }
    }
    if (inspector != null && inspector.isNotEmpty) {
      query =
          query.where('inspectionMetadata.inspectorName', isEqualTo: inspector);
    }
    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => SavedReport.fromMap(doc.data(), doc.id))
        .toList();
  }

  Widget _buildTile(SavedReport report) {
    final meta = InspectionMetadata.fromMap(report.inspectionMetadata);
    String date = meta.inspectionDate.toLocal().toString().split(' ')[0];
    String subtitle = '${meta.clientName} • $date';
    String? thumbUrl;
    for (var photos in report.sectionPhotos.values) {
      if (photos.isNotEmpty) {
        thumbUrl = photos.first.photoUrl;
        break;
      }
    }
    return ListTile(
      leading: thumbUrl != null
          ? Image.network(thumbUrl!, width: 56, height: 56, fit: BoxFit.cover)
          : const Icon(Icons.description),
      title: Text(meta.propertyAddress),
      subtitle: Text(subtitle),
      onTap: () {
        final sections = <String, List<PhotoEntry>>{};
        report.sectionPhotos.forEach((key, value) {
          sections[key] =
              value.map((e) => PhotoEntry(url: e.photoUrl, label: e.label)).toList();
        });
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReportPreviewScreen(
              metadata: meta,
              sections: sections,
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
                          items: const [
                            DropdownMenuItem(
                                value: 'newest', child: Text('Newest')),
                            DropdownMenuItem(
                                value: 'oldest', child: Text('Oldest')),
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
