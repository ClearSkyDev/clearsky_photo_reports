import 'package:flutter/material.dart';

import '../services/changelog_service.dart';
import '../screens/changelog_screen.dart';

class ChangelogBanner extends StatefulWidget {
  const ChangelogBanner({super.key});

  @override
  State<ChangelogBanner> createState() => _ChangelogBannerState();
}

class _ChangelogBannerState extends State<ChangelogBanner> {
  bool _show = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final show = await ChangelogService.instance.shouldShowChangelog();
    if (mounted) setState(() => _show = show);
  }

  void _dismiss() {
    ChangelogService.instance.markSeen();
    setState(() => _show = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_show) return const SizedBox.shrink();
    final entry = ChangelogService.instance.latest;
    return MaterialBanner(
      backgroundColor: Colors.blueGrey.shade100,
      content: Text('Updated to ${entry?.version ?? ''}!'),
      leading: const Icon(Icons.new_releases),
      actions: [
        TextButton(
          onPressed: () {
            _dismiss();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChangelogScreen()),
            );
          },
          child: const Text('View'),
        ),
        TextButton(
          onPressed: _dismiss,
          child: const Text('Dismiss'),
        ),
      ],
    );
  }
}
