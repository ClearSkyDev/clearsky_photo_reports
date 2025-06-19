import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;

import '../models/inspection_report.dart';

class AnalyticsDashboardScreen extends StatelessWidget {
  final List<InspectionReport> reports;

  const AnalyticsDashboardScreen({Key? key, required this.reports}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final int total = reports.length;
    final int synced = reports.where((r) => r.synced).length;
    final int unsynced = total - synced;

    final List<ChartData> pieData = [
      ChartData('Synced', synced, Colors.green),
      ChartData('Unsynced', unsynced, Colors.red),
    ];

    final List<ChartData> barData = [
      ChartData('Total', total, Colors.blue),
      ChartData('Synced', synced, Colors.green),
      ChartData('Unsynced', unsynced, Colors.red),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics Overview')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: total == 0
            ? const Center(child: Text('No reports to analyze.'))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Total Inspections: $total', style: Theme.of(context).textTheme.headline6),
                  const SizedBox(height: 8),
                  Expanded(
                    child: charts.PieChart(
                      [
                        charts.Series<ChartData, String>(
                          id: 'ReportSyncPie',
                          domainFn: (ChartData data, _) => data.label,
                          measureFn: (ChartData data, _) => data.value,
                          colorFn: (ChartData data, _) => charts.ColorUtil.fromDartColor(data.color),
                          data: pieData,
                          labelAccessorFn: (ChartData row, _) => '${row.label}: ${row.value}',
                        )
                      ],
                      animate: true,
                      defaultRenderer: charts.ArcRendererConfig(arcRendererDecorators: [
                        charts.ArcLabelDecorator(labelPosition: charts.ArcLabelPosition.outside)
                      ]),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: charts.BarChart(
                      [
                        charts.Series<ChartData, String>(
                          id: 'ReportSyncBars',
                          domainFn: (ChartData data, _) => data.label,
                          measureFn: (ChartData data, _) => data.value,
                          colorFn: (ChartData data, _) => charts.ColorUtil.fromDartColor(data.color),
                          data: barData,
                        )
                      ],
                      animate: true,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class ChartData {
  final String label;
  final int value;
  final Color color;

  ChartData(this.label, this.value, this.color);
}
