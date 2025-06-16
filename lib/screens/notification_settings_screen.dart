import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/notification_preferences.dart';
import '../services/notification_service.dart';

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
      return const Scaffold(
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
