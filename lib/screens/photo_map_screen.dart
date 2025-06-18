import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';


import '../models/photo_entry.dart';

class PhotoMapScreen extends StatelessWidget {
  final List<PhotoEntry> photos;

  const PhotoMapScreen({super.key, required this.photos});

  @override
  Widget build(BuildContext context) {
    final gpsPhotos =
        photos.where((p) => p.latitude != null && p.longitude != null).toList();

    final center = gpsPhotos.isNotEmpty
        ? LatLng(gpsPhotos.first.latitude!, gpsPhotos.first.longitude!)
        : const LatLng(0, 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Inspection Map')),
      body: FlutterMap(
        options: MapOptions(center: center, zoom: 15),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: ['a', 'b', 'c'],
            userAgentPackageName: 'com.clearsky.app',
          ),
          MarkerLayer(
            markers: [
              for (final p in gpsPhotos)
                Marker(
                  point: LatLng(p.latitude!, p.longitude!),
                  width: 40,
                  height: 40,
                  builder: (context) => GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (p.url.startsWith('http'))
                                Image.network(p.url,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover)
                              else
                                Image.file(File(p.url),
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover),
                              const SizedBox(height: 8),
                              Text(p.label),
                              if (p.note.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  p.note,
                                  style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                    child: const Icon(Icons.location_on,
                        color: Colors.redAccent, size: 40),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
