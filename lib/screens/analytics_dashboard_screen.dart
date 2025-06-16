import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/report_metrics.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  List<ReportMetrics> _metrics = [];
  bool _loading = true;
  final TextEditingController _inspectorController = TextEditingController();
  final TextEditingController _zipController = TextEditingController();
  DateTimeRange? _range;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final snap = await FirebaseFirestore.instance.collection('metrics').get();
    _metrics = snap.docs
        .map((d) => ReportMetrics.fromMap(d.id, d.data()))
        .toList();
    setState(() => _loading = false);
  }

  List<ReportMetrics> get _filtered {
    return _metrics.where((m) {
      if (_inspectorController.text.isNotEmpty &&
          !m.inspectorId
              .toLowerCase()
              .contains(_inspectorController.text.toLowerCase())) {
        return false;
      }
      if (_zipController.text.isNotEmpty && m.zipCode != _zipController.text) {
        return false;
      }
      if (_range != null) {
        if (m.createdAt.isBefore(_range!.start) ||
            m.createdAt.isAfter(_range!.end)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  int get _totalReports => _filtered.length;

  double get _avgDuration {
    final durations = _filtered
        .where((m) => m.finalizedAt != null && m.finalizedAt!.isAfter(m.createdAt))
        .map((m) => m.finalizedAt!.difference(m.createdAt).inMinutes)
        .toList();
    if (durations.isEmpty) return 0;
    return durations.reduce((a, b) => a + b) / durations.length;
  }

  double get _avgPhotos {
    if (_filtered.isEmpty) return 0;
    final total = _filtered.map((m) => m.photoCount).reduce((a, b) => a + b);
    return total / _filtered.length;
  }

  Map<DateTime, int> get _perDay {
    final map = <DateTime, int>{};
    for (final m in _filtered) {
      final day = DateTime(m.createdAt.year, m.createdAt.month, m.createdAt.day);
      map[day] = (map[day] ?? 0) + 1;
    }
    return map;
  }

  Map<String, int> get _perInspector {
    final map = <String, int>{};
    for (final m in _filtered) {
      map[m.inspectorId] = (map[m.inspectorId] ?? 0) + 1;
    }
    return map;
  }

  Map<String, int> get _statusCounts {
    final map = <String, int>{};
    for (final m in _filtered) {
      map[m.status] = (map[m.status] ?? 0) + 1;
    }
    return map;
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _range,
    );
    if (range != null) setState(() => _range = range);
  }

  Future<void> _exportCsv() async {
    final rows = <List<dynamic>>[
      ['id', 'inspectorId', 'createdAt', 'finalizedAt', 'photoCount', 'status', 'zipCode']
    ];
    for (final m in _filtered) {
      rows.add([
        m.id,
        m.inspectorId,
        m.createdAt.toIso8601String(),
        m.finalizedAt?.toIso8601String() ?? '',
        m.photoCount,
        m.status,
        m.zipCode ?? ''
      ]);
    }
    final csv = const ListToCsvConverter().convert(rows);
    await Printing.sharePdf(bytes: pw.Document().save(), filename: 'dummy.pdf');
    await Printing.share(csv); // share as text
  }

  Future<void> _exportPdf() async {
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        build: (context) => pw.Center(
          child: pw.Text('Analytics Export - Total $_totalReports reports'),
        ),
      ),
    );
    await Printing.layoutPdf(onLayout: (_) async => doc.save());
  }

  String _generateInsights() {
    if (_filtered.isEmpty) return 'No data';
    final mostInspected = _perInspector.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
    return 'Most reports by $mostInspected. Average duration ${_avgDuration.toStringAsFixed(1)} mins.';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
          appBar: AppBar(title: Text('Analytics')),
          body: Center(child: CircularProgressIndicator()));
    }

    final perDay = _perDay.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final perInspector = _perInspector;
    final statusCounts = _statusCounts;

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inspectorController,
                      decoration:
                          const InputDecoration(labelText: 'Inspector'),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _zipController,
                      decoration:
                          const InputDecoration(labelText: 'Zip Code'),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  IconButton(
                    onPressed: _pickRange,
                    icon: const Icon(Icons.date_range),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                children: [
                  _kpiTile('Total Reports', '$_totalReports'),
                  _kpiTile('Avg Duration', '${_avgDuration.toStringAsFixed(1)}m'),
                  _kpiTile('Avg Photos', '${_avgPhotos.toStringAsFixed(1)}'),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    lineBarsData: [
                      LineChartBarData(
                        spots: [
                          for (var e in perDay)
                            FlSpot(e.key.millisecondsSinceEpoch.toDouble(),
                                e.value.toDouble())
                        ],
                      )
                    ],
                    titlesData: FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    barGroups: [
                      for (var e in perInspector.entries)
                        BarChartGroupData(x: perInspector.keys.toList().indexOf(e.key), barRods: [BarChartRodData(toY: e.value.toDouble())])
                    ],
                    titlesData: FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sections: [
                      for (var e in statusCounts.entries)
                        PieChartSectionData(value: e.value.toDouble(), title: e.key)
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(_generateInsights()),
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton(onPressed: _exportCsv, child: const Text('Export CSV')),
                  const SizedBox(width: 8),
                  ElevatedButton(onPressed: _exportPdf, child: const Text('Export PDF')),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _kpiTile(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label),
      ],
    );
  }
}
