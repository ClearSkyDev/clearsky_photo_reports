import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models/inspection_report.dart';

class AnalyticsDashboardScreen extends StatelessWidget {
  final List<InspectionReport> reports;

  const AnalyticsDashboardScreen({super.key, required this.reports});

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
                  Text('Total Inspections: $total',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        sections: pieData
                            .map((d) => PieChartSectionData(
                                  value: d.value.toDouble(),
                                  color: d.color,
                                  title: '${d.label}: ${d.value}',
                                  titleStyle: const TextStyle(
                                      fontSize: 14, color: Colors.white),
                                ))
                            .toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: BarChart(
                      BarChartData(
                        barGroups: [
                          for (int i = 0; i < barData.length; i++)
                            BarChartGroupData(
                              x: i,
                              barRods: [
                                BarChartRodData(
                                  toY: barData[i].value.toDouble(),
                                  color: barData[i].color,
                                  width: 20,
                                  borderRadius: BorderRadius.zero,
                                ),
                              ],
                            ),
                        ],
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final idx = value.toInt();
                                if (idx >= 0 && idx < barData.length) {
                                  return Text(barData[idx].label);
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                          leftTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        gridData: const FlGridData(show: false),
                      ),
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
