import 'package:flutter/material.dart';

class ClearSkyHeader extends StatelessWidget {
  const ClearSkyHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset('assets/images/clearsky_logo.png', height: 40),
        const SizedBox(width: 8),
        Text('ClearSky', style: Theme.of(context).textTheme.headlineSmall),
      ],
    );
  }
}
