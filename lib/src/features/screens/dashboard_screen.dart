import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'dart:io';

import '../../core/models/inspector_user.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/offline_sync_service.dart';
import '../widgets/ai_chat_button.dart';
import '../widgets/ai_chat_drawer.dart';
import '../widgets/changelog_banner.dart';

class DashboardScreen extends StatefulWidget {
  final InspectorUser user;
  const DashboardScreen({super.key, required this.user});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    debugPrint('[DashboardScreen] build');
    final key = const String.fromEnvironment('OPENAI_API_KEY', defaultValue: '')
            .isNotEmpty
        ? const String.fromEnvironment('OPENAI_API_KEY')
        : (Platform.environment['OPENAI_API_KEY'] ?? '');
    return Scaffold(
      endDrawer:
          AiChatDrawer(reportId: 'dashboard', apiKey: key, context: null),
      floatingActionButton: Builder(
        builder: (context) => AiChatButton(
          reportId: 'dashboard',
          apiKey: key,
        ),
      ),
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: OfflineSyncService.instance.online,
            builder: (context, online, _) {
              if (!online) {
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Chip(label: Text('Offline')),
                );
              }
              return ValueListenableBuilder<double>(
                valueListenable: OfflineSyncService.instance.progress,
                builder: (context, progress, __) {
                  return Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.sync),
                        tooltip: 'Sync Now',
                        onPressed: OfflineSyncService.instance.syncDrafts,
                      ),
                      if (progress > 0 && progress < 1)
                        const Positioned(
                          right: 4,
                          top: 4,
                          child: SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      else if (OfflineSyncService.instance.pendingCount > 0)
                        Positioned(
                          right: 4,
                          top: 4,
                          child: CircleAvatar(
                            radius: 8,
                            backgroundColor: Colors.red,
                            child: Text(
                              '${OfflineSyncService.instance.pendingCount}',
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.white),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => AuthService().signOut(),
          ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const ChangelogBanner(),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/history'),
              child: const Text('My Reports'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/history'),
              child: const Text('Team Reports'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/reportMap'),
              child: const Text('Map View'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/search'),
              child: const Text('Search Reports'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/invoices'),
              child: const Text('Unpaid Invoices'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/syncHistory'),
              child: const Text('Sync History'),
            ),
            if (widget.user.role == UserRole.admin)
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/manageTeam'),
                child: const Text('Manage Team'),
              ),
            if (widget.user.role == UserRole.admin)
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/publicLinks'),
                child: const Text('Public Links'),
              ),
            if (widget.user.role == UserRole.admin)
              ElevatedButton(
                onPressed: () =>
                    Navigator.pushNamed(context, '/signatureStatus'),
                child: const Text('Signature Status'),
              ),
            if (widget.user.role == UserRole.admin)
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/analytics'),
                child: const Text('Analytics Dashboard'),
              ),
            if (widget.user.role == UserRole.admin)
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/adminLogs'),
                child: const Text('Audit Logs'),
              ),
          ],
        ),
      ),
    );
  }
}
