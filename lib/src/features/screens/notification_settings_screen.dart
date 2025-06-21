import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/models/notification_preferences.dart';
import '../../core/services/notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  NotificationPreferences _prefs = const NotificationPreferences();
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString('notif_prefs');
    if (raw != null) {
      _prefs = NotificationPreferences.fromMap(
          Map<String, dynamic>.from(jsonDecode(raw)));
    }
    if (!mounted) return;
    setState(() => _loaded = true);
  }

  Future<void> _save() async {
    await NotificationService.instance.savePrefs(_prefs);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification settings saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Notification Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('New Messages'),
            value: _prefs.newMessage,
            onChanged: (val) => setState(() {
              _prefs = _prefs.copyWith(newMessage: val);
            }),
          ),
          SwitchListTile(
            title: const Text('Report Finalized/Signed'),
            value: _prefs.reportFinalized,
            onChanged: (val) => setState(() {
              _prefs = _prefs.copyWith(reportFinalized: val);
            }),
          ),
          SwitchListTile(
            title: const Text('Invoice Updates'),
            value: _prefs.invoiceUpdate,
            onChanged: (val) => setState(() {
              _prefs = _prefs.copyWith(invoiceUpdate: val);
            }),
          ),
          SwitchListTile(
            title: const Text('AI Summary Ready'),
            value: _prefs.aiSummary,
            onChanged: (val) => setState(() {
              _prefs = _prefs.copyWith(aiSummary: val);
            }),
          ),
          SwitchListTile(
            title: const Text('Weekly Snapshot Email'),
            value: _prefs.weeklySnapshot,
            onChanged: (val) => setState(() {
              _prefs = _prefs.copyWith(weeklySnapshot: val);
            }),
          ),
          if (_prefs.weeklySnapshot)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  DropdownButton<int>(
                    value: _prefs.snapshotDay,
                    items: [
                      const DropdownMenuItem(value: 1, child: Text('Mon')),
                      const DropdownMenuItem(value: 2, child: Text('Tue')),
                      const DropdownMenuItem(value: 3, child: Text('Wed')),
                      const DropdownMenuItem(value: 4, child: Text('Thu')),
                      const DropdownMenuItem(value: 5, child: Text('Fri')),
                      const DropdownMenuItem(value: 6, child: Text('Sat')),
                      const DropdownMenuItem(value: 0, child: Text('Sun')),
                    ],
                    onChanged: (val) => setState(() {
                      if (val != null) {
                        _prefs = _prefs.copyWith(snapshotDay: val);
                      }
                    }),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<int>(
                    value: _prefs.snapshotHour,
                    items: [
                      for (int h = 0; h < 24; h++)
                        DropdownMenuItem(value: h, child: Text('$h:00')),
                    ],
                    onChanged: (val) => setState(() {
                      if (val != null) {
                        _prefs = _prefs.copyWith(snapshotHour: val);
                      }
                    }),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _save,
              child: const Text('Save'),
            ),
          )
        ],
      ),
    );
  }
}
