import 'package:flutter/material.dart';

import '../services/sync_history_service.dart';
import '../models/sync_log_entry.dart';

class SyncHistoryScreen extends StatefulWidget {
  const SyncHistoryScreen({super.key});

  @override
  State<SyncHistoryScreen> createState() => _SyncHistoryScreenState();
}

class _SyncHistoryScreenState extends State<SyncHistoryScreen> {
  List<SyncLogEntry> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _entries = SyncHistoryService.instance.loadEntries();
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sync History')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _entries.length,
              itemBuilder: (context, index) {
                final e = _entries[index];
                return ListTile(
                  leading: Icon(
                    e.success ? Icons.check_circle : Icons.error,
                    color: e.success ? Colors.green : Colors.red,
                  ),
                  title: Text(e.reportId),
                  subtitle: Text('${e.timestamp.toLocal()}\n${e.message}'),
                );
              },
            ),
    );
  }
}
