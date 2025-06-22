import 'package:flutter/material.dart';

import '../../app/app_theme.dart';

/// Landing screen with project creation and upgrade prompts.
class HomeScreen extends StatelessWidget {
  final int freeReportsRemaining;
  final bool isSubscribed;

  const HomeScreen({
    super.key,
    required this.freeReportsRemaining,
    required this.isSubscribed,
  });

  void _handleCreateProject(BuildContext context) {
    Navigator.pushNamed(context, '/projectDetails');
  }

  void _handleUpgrade(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Upgrade Required'),
        content: const Text(
          'Please upgrade your account to continue using ClearSky.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _checkSubscription(BuildContext context) {
    if (freeReportsRemaining <= 0 && !isSubscribed) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Upgrade Needed'),
          content: const Text(
            'You have reached your free report limit. Upgrade to continue.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => _handleUpgrade(context),
              child: const Text('Upgrade'),
            ),
          ],
        ),
      );
    } else {
      _handleCreateProject(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.clearSkyTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: AppTheme.clearSkyTheme.primaryColor,
      ),
      body: Column(
        children: [
          if (!isSubscribed)
            Container(
              padding: const EdgeInsets.all(12),
              color: AppTheme.clearSkyTheme.colorScheme.secondary,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Free trial: $freeReportsRemaining report${freeReportsRemaining == 1 ? '' : 's'} remaining',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton(
                    onPressed: () => _handleUpgrade(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8A65),
                    ),
                    child: const Text('Upgrade'),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          Text(
            'ClearSky Photo Reports',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const Text('Create professional inspection reports'),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _checkSubscription(context),
            icon: const Icon(Icons.add),
            label: const Text('Create Project'),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (i) {
          // TODO: implement navigation
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.camera_alt), label: 'Camera'),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
