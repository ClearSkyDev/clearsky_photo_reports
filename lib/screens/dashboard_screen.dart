import 'package:flutter/material.dart';

import '../models/inspector_user.dart';
import '../services/auth_service.dart';

class DashboardScreen extends StatelessWidget {
  final InspectorUser user;
  const DashboardScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
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
          ],
        ),
      ),
    );
  }
}
