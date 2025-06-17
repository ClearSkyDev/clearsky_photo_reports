import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models/inspector_user.dart';
import 'screens/dashboard_screen.dart';
import 'screens/sectioned_photo_upload_screen.dart';
import 'screens/report_screen.dart';
import 'screens/report_settings_screen.dart';

class MainNavScaffold extends StatefulWidget {
  final InspectorUser user;
  const MainNavScaffold({super.key, required this.user});

  @override
  State<MainNavScaffold> createState() => _MainNavScaffoldState();
}

class _MainNavScaffoldState extends State<MainNavScaffold> {
  int _index = 0;

  late final List<Widget> _pages = [
    DashboardScreen(user: widget.user),
    const SectionedPhotoUploadScreen(),
    const ReportScreen(),
    const ReportSettingsScreen(),
  ];

  void _onItemTapped(int i) {
    HapticFeedback.selectionClick();
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.photo_camera), label: 'Photos'),
          BottomNavigationBarItem(icon: Icon(Icons.picture_as_pdf), label: 'Report'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
