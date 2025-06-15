import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ClearSky Home')),
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
