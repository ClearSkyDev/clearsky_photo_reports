import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/models/photo_entry.dart';

class PhotoMapScreen extends StatelessWidget {
  final List<PhotoEntry> photos;

  const PhotoMapScreen({super.key, required this.photos});

  @override
  Widget build(BuildContext context) {
    final gpsPhotos =
        photos.where((p) => p.latitude != null && p.longitude != null).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Inspection Map')),
      body: ListView.builder(
        itemCount: gpsPhotos.length,
        itemBuilder: (context, index) {
          final p = gpsPhotos[index];
          return ListTile(
            leading: const Icon(Icons.location_on, color: Colors.redAccent),
            title: Text(p.label),
            subtitle: Text('Lat: ${p.latitude}, Lng: ${p.longitude}'),
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (p.url.startsWith('http'))
                        Image.network(p.url,
                            width: 100, height: 100, fit: BoxFit.cover)
                      else
                        Image.file(File(p.url),
                            width: 100, height: 100, fit: BoxFit.cover),
                      const SizedBox(height: 8),
                      Text(p.label),
                      if (p.note.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          p.note,
                          style: const TextStyle(
                              fontStyle: FontStyle.italic, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
