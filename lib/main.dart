import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/report_screen.dart';
import 'screens/photo_upload_screen.dart';

void main() {
  runApp(ClearSkyApp());
}

class ClearSkyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ClearSky Photo Reports',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => HomeScreen(),
        '/report': (context) => ReportScreen(),
        '/upload': (context) => PhotoUploadScreen(),
      },
    );
  }
}