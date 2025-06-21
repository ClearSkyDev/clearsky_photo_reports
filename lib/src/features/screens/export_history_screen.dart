import 'package:flutter/material.dart';

import '../../core/models/export_log_entry.dart';
import '../../core/utils/export_log.dart';

class ExportHistoryScreen extends StatefulWidget {
  const ExportHistoryScreen({super.key});

  @override
  State<ExportHistoryScreen> createState() => _ExportHistoryScreenState();
}

class _ExportHistoryScreenState extends State<ExportHistoryScreen> {
  List<ExportLogEntry> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _entries = await ExportLog.load();
    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Export History')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? const Center(child: Text('No exports yet'))
              : ListView.builder(
                  itemCount: _entries.length,
                  itemBuilder: (context, index) {
                    final e = _entries[index];
                    final date = e.timestamp.toLocal().toString().split('.')[0];
                    return ListTile(
                      leading: Icon(e.type.toLowerCase() == 'pdf'
                          ? Icons.picture_as_pdf
                          : Icons.language),
                      title: Text(e.reportName),
                      subtitle:
                          Text('$date${e.wasOffline ? ' • Offline' : ''}'),
                    );
                  },
                ),
    );
  }
}
