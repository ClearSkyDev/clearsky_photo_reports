import 'package:flutter/material.dart';

class AuditLogEntry {
  final DateTime timestamp;
  final String user;
  final String action;
  final String target;
  final String? extraInfo;

  AuditLogEntry({
    required this.timestamp,
    required this.user,
    required this.action,
    required this.target,
    this.extraInfo,
  });
}

class AdminAuditLogScreen extends StatelessWidget {
  final List<AuditLogEntry> logs;

  const AdminAuditLogScreen({
    super.key,
    required this.logs,
  });

  @override
  Widget build(BuildContext context) {
    logs.sort(
        (a, b) => b.timestamp.compareTo(a.timestamp)); // Most recent first

    return Scaffold(
      appBar: AppBar(title: const Text('Audit Log')),
      body: logs.isEmpty
          ? const Center(child: Text('No audit entries found.'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                return Card(
                  child: ListTile(
                    title: Text('${log.user} ${log.action}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Target: ${log.target}'),
                        if (log.extraInfo != null)
                          Text('Details: ${log.extraInfo!}',
                              style: const TextStyle(fontSize: 13)),
                        Text(
                          _formatTime(log.timestamp),
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                    leading: const Icon(Icons.history),
                  ),
                );
              },
            ),
    );
  }

  String _formatTime(DateTime dt) {
    final date =
        '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    final time =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '$date $time';
  }
}
