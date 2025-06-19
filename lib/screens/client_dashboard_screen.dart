import 'package:flutter/material.dart';

class ClientDashboardScreen extends StatelessWidget {
  const ClientDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Client Dashboard'),
      ),
      body: const Center(
        child: Text('Welcome to the Client Dashboard!'),
      ),
    );
  }
}
