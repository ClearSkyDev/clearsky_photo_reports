import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/audit_log_entry.dart';
import '../services/audit_log_service.dart';

class AdminAuditLogScreen extends StatefulWidget {
  const AdminAuditLogScreen({super.key});

  @override
  State<AdminAuditLogScreen> createState() => _AdminAuditLogScreenState();
}

class _AdminAuditLogScreenState extends State<AdminAuditLogScreen> {
  final _userController = TextEditingController();
  final _actionController = TextEditingController();
  final _targetController = TextEditingController();
  DateTimeRange? _range;
  List<AuditLogEntry> _logs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _range,
    );
    if (range != null) {
      setState(() => _range = range);
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _logs = await AuditLogService().fetchLogs(
      userId: _userController.text.trim().isEmpty
          ? null
          : _userController.text.trim(),
      action: _actionController.text.trim().isEmpty
          ? null
          : _actionController.text.trim(),
      targetId: _targetController.text.trim().isEmpty
          ? null
          : _targetController.text.trim(),
      range: _range,
    );
    setState(() => _loading = false);
  }

  Future<void> _exportCsv() async {
    final rows = [
      ['userId', 'action', 'targetId', 'targetType', 'notes', 'timestamp']
    ];
    for (final l in _logs) {
      rows.add([
        l.userId,
        l.action,
        l.targetId ?? '',
        l.targetType ?? '',
        l.notes ?? '',
        l.timestamp.toIso8601String()
      ]);
    }
    final csv = const ListToCsvConverter().convert(rows);
    await Clipboard.setData(ClipboardData(text: csv));
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('CSV copied to clipboard')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Audit Logs')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _userController,
                    decoration: const InputDecoration(labelText: 'User ID'),
                    onChanged: (_) => _load(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _actionController,
                    decoration: const InputDecoration(labelText: 'Action'),
                    onChanged: (_) => _load(),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _targetController,
                    decoration: const InputDecoration(labelText: 'Target ID'),
                    onChanged: (_) => _load(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.date_range),
                  onPressed: _pickRange,
                ),
                IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: _exportCsv,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _logs.length,
                      itemBuilder: (c, i) {
                        final log = _logs[i];
                        final isSensitive = log.action.contains('delete') ||
                            log.action.contains('login') ||
                            log.action.contains('export');
                        return ListTile(
                          leading: isSensitive
                              ? const Icon(Icons.warning, color: Colors.red)
                              : null,
                          title: Text(log.action),
                          subtitle: Text(
                              '${log.userId} • ${log.targetId ?? ''} • ${log.timestamp.toLocal()}'),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
