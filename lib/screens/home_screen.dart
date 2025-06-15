import 'package:flutter/material.dart';

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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/upload'),
              child: const Text('Upload Photos'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/report'),
              child: const Text('Generate Report'),
            ),
          ],
        ),
      ),
    );
  }
}
