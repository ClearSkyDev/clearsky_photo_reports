import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/report_metrics.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  final List<ReportMetrics> allMetrics;

  const AnalyticsDashboardScreen({super.key, required this.allMetrics});

  @override
  State<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  String _selectedRange = 'Last 30 Days';

  List<ReportMetrics> get _filteredMetrics {
    final now = DateTime.now();
    if (_selectedRange == 'Last 7 Days') {
      return widget.allMetrics.where((m) => m.createdAt.isAfter(now.subtract(const Duration(days: 7)))).toList();
    } else if (_selectedRange == 'Last 30 Days') {
      return widget.allMetrics.where((m) => m.createdAt.isAfter(now.subtract(const Duration(days: 30)))).toList();
    }
    return widget.allMetrics;
  }

  @override
  Widget build(BuildContext context) {
    final totalReports = _filteredMetrics.length;
    final totalPhotos = _filteredMetrics.fold<int>(0, (sum, m) => sum + m.totalPhotos);
    final avgPhotos = totalReports > 0 ? (totalPhotos / totalReports).toStringAsFixed(1) : '0';
    final totalExports = _filteredMetrics.where((m) => m.exportedToPdf || m.exportedToHtml).length;
    final totalDuration = _filteredMetrics.fold<Duration>(Duration.zero, (sum, m) => sum + m.inspectionDuration);
    final avgDuration = totalReports > 0 ? _formatDuration(totalDuration ~/ totalReports) : 'N/A';

    final roleCounts = {
      'Ladder Assist': _filteredMetrics.where((m) => m.inspectorRole == 'Ladder Assist').length,
      'Adjuster': _filteredMetrics.where((m) => m.inspectorRole == 'Adjuster').length,
      'Contractor': _filteredMetrics.where((m) => m.inspectorRole == 'Contractor').length,
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (val) => setState(() => _selectedRange = val),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'Last 7 Days', child: Text('Last 7 Days')),
              PopupMenuItem(value: 'Last 30 Days', child: Text('Last 30 Days')),
              PopupMenuItem(value: 'All Time', child: Text('All Time')),
            ],
            icon: const Icon(Icons.filter_alt),
          ),
          IconButton(
            onPressed: () => _exportAsPDF(_filteredMetrics),
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export PDF',
          ),
          IconButton(
            onPressed: () => _exportAsCSV(_filteredMetrics),
            icon: const Icon(Icons.table_chart),
            tooltip: 'Export CSV',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            _selectedRange,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _metricTile('📊 Total Reports', totalReports.toString()),
          _metricTile('📷 Avg Photos per Report', avgPhotos),
          _metricTile('🕒 Avg Duration', avgDuration),
          _metricTile('📤 Reports Exported', totalExports.toString()),
          const SizedBox(height: 24),
          const Text('🔧 Role Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          _buildPieChart(roleCounts, totalReports),
          const SizedBox(height: 24),
          const Text('📈 Weekly Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildBarChart(),
        ],
      ),
    );
  }

  Widget _metricTile(String label, String value) {
    return Card(
      child: ListTile(
        title: Text(label),
        trailing: Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildPieChart(Map<String, int> counts, int total) {
    final pieSections = counts.entries.map((e) {
      final percentage = total > 0 ? (e.value / total) * 100 : 0;
      return PieChartSectionData(
        color: e.key == 'Ladder Assist' ? Colors.blue : e.key == 'Adjuster' ? Colors.green : Colors.orange,
        value: e.value.toDouble(),
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 50,
      );
    }).toList();

    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sections: pieSections,
          centerSpaceRadius: 40,
          sectionsSpace: 2,
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    final today = DateTime.now();
    final last7Days = List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));
    final reportCounts = Map.fromEntries(last7Days.map((d) {
      final count = _filteredMetrics.where((m) =>
              m.createdAt.year == d.year &&
              m.createdAt.month == d.month &&
              m.createdAt.day == d.day)
          .length;
      return MapEntry(d, count);
    }));

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= reportCounts.length) return const Text('');
                  final day = reportCounts.keys.elementAt(index);
                  return Text('${day.month}/${day.day}', style: const TextStyle(fontSize: 11));
                },
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 30),
            ),
          ),
          barGroups: List.generate(reportCounts.length, (index) {
            final day = reportCounts.keys.elementAt(index);
            final count = reportCounts[day]!;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(toY: count.toDouble(), color: Colors.blueAccent, width: 16),
              ],
            );
          }),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) => '${d.inMinutes} min';

  void _exportAsPDF(List<ReportMetrics> metrics) {
    // TODO: Implement real PDF export
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exported as PDF (stubbed).')),
    );
  }

  void _exportAsCSV(List<ReportMetrics> metrics) {
    // TODO: Implement real CSV export
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exported as CSV (stubbed).')),
    );
  }
}
