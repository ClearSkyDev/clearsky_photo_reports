import 'package:flutter/material.dart';

import 'client_dashboard_screen.dart';
import 'guided_capture_screen.dart';
import 'analytics_dashboard_screen.dart';

import '../models/inspection_report.dart';

class HomeScreen extends StatelessWidget {
  final List<InspectionReport> allReports;

  const HomeScreen({Key? key, required this.allReports}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ClearSky Photo Reports'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _HomeCard(
            icon: Icons.camera_alt,
            title: 'Start Guided Inspection',
            subtitle: 'Step-by-step photo intake',
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GuidedCaptureScreen()),
              );
              // Optionally handle result here
            },
          ),
          _HomeCard(
            icon: Icons.dashboard_customize,
            title: 'View All Reports',
            subtitle: 'See synced and unsynced inspections',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ClientDashboardScreen(),
                ),
              );
            },
          ),
          _HomeCard(
            icon: Icons.bar_chart,
            title: 'Analytics',
            subtitle: 'Sync status and progress tracking',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AnalyticsDashboardScreen(reports: allReports),
                ),
              );
            },
          ),
          _HomeCard(
            icon: Icons.settings,
            title: 'Settings',
            subtitle: 'Theme, sync, account (coming soon)',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings not implemented yet.')),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HomeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _HomeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(icon, size: 32, color: Colors.blueGrey),
        title: Text(title, style: Theme.of(context).textTheme.subtitle1),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
        onTap: onTap,
      ),
    );
  }
}
