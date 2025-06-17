import 'package:flutter/material.dart';
import '../utils/profile_storage.dart';
import '../models/inspector_profile.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/images/clearsky_logo.png', height: 32),
            const SizedBox(width: 8),
            const Text('ClearSky Photo Reports'),
          ],
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/metadata'),
                child: const Text('Upload Photos'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/sectionedUpload'),
                child: const Text('Roof Intake Flow'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/droneMedia'),
                child: const Text('Drone Media Upload'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/report'),
                child: const Text('Generate Report'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
              onPressed: () async {
                final profile = await ProfileStorage.load();
                String? name;
                if (profile != null && profile.role != InspectorRole.admin) {
                  name = profile.name;
                }
                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReportHistoryScreen(
                        inspectorName: name,
                      ),
                    ),
                  );
                }
              },
              child: const Text('View History'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/settings'),
                child: const Text('Report Settings'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/templates'),
                child: const Text('Manage Templates'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/profile'),
                child: const Text('Profile'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/theme'),
                child: const Text('Report Theme'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/learning'),
                child: const Text('AI Learning'),
              ),
          ],
        ),
      ),
    );
  }
}
