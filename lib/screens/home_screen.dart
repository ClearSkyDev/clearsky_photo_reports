import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('ClearSky Home')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/upload'),
              child: Text('Upload Photos'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/report'),
              child: Text('Generate Report'),
            ),
          ],
        ),
      ),
    );
  }
}
