import 'package:flutter/material.dart';

import '../models/inspector_user.dart';
import '../services/auth_service.dart';
import '../services/offline_sync_service.dart';

class DashboardScreen extends StatelessWidget {
  final InspectorUser user;
  const DashboardScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.sync),
                    onPressed: OfflineSyncService.instance.syncDrafts,
                  ),
                  if (OfflineSyncService.instance.pendingCount > 0)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: CircleAvatar(
                        radius: 8,
                        backgroundColor: Colors.red,
                        child: Text(
                          '${OfflineSyncService.instance.pendingCount}',
                          style:
                              const TextStyle(fontSize: 10, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => AuthService().signOut(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
            if (user.role == UserRole.admin)
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/manageTeam'),
                child: const Text('Manage Team'),
              ),
            if (user.role == UserRole.admin)
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/publicLinks'),
                child: const Text('Public Links'),
              ),
            if (user.role == UserRole.admin)
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/signatureStatus'),
                child: const Text('Signature Status'),
              ),
            if (user.role == UserRole.admin)
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/analytics'),
                child: const Text('Analytics Dashboard'),
              ),
            if (user.role == UserRole.admin)
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
