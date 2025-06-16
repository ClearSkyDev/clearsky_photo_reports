import 'dart:io';

import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

import '../models/photo_entry.dart';

class PhotoDetailScreen extends StatefulWidget {
  final PhotoEntry entry;
  const PhotoDetailScreen({super.key, required this.entry});

  @override
  State<PhotoDetailScreen> createState() => _PhotoDetailScreenState();
}

class _PhotoDetailScreenState extends State<PhotoDetailScreen> {
  late final SignatureController _controller;
  Color _penColor = Colors.red;
  bool _markupMode = false;

  @override
  void initState() {
    super.initState();
    _controller = SignatureController(
      penStrokeWidth: 3,
      penColor: _penColor,
      exportBackgroundColor: Colors.transparent,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveMarkup() async {
    if (_controller.isEmpty) return;
    final overlayBytes = await _controller.toPngBytes();
    if (overlayBytes == null) return;
    final file = File(widget.entry.url);
    if (!await file.exists()) return;
    final baseBytes = await file.readAsBytes();
    final baseImage = img.decodeImage(baseBytes);
    final overlayImage = img.decodeImage(overlayBytes);
    if (baseImage == null || overlayImage == null) return;
    final resizedOverlay = img.copyResize(overlayImage,
        width: baseImage.width, height: baseImage.height);
    img.drawImage(baseImage, resizedOverlay);

    final dir = p.dirname(file.path);
    final newPath = p.join(
        dir, '${p.basenameWithoutExtension(file.path)}_marked.jpg');
    final newFile = File(newPath);
    await newFile.writeAsBytes(img.encodeJpg(baseImage));
    setState(() {
      widget.entry.originalUrl ??= widget.entry.url;
      widget.entry.url = newFile.path;
    });
    Navigator.pop(context, true);
  }

  void _setColor(Color color) {
    setState(() {
      _penColor = color;
      _controller.penColor = color;
    });
  }

  Widget _buildToolbar() {
    if (!_markupMode) {
      return IconButton(
        icon: const Icon(Icons.brush),
        onPressed: () => setState(() => _markupMode = true),
      );
    }
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            setState(() {
              _markupMode = false;
              _controller.clear();
            });
          },
        ),
        IconButton(
          icon: const Icon(Icons.delete),
          onPressed: _controller.clear,
        ),
        IconButton(
          icon: const Icon(Icons.save),
          onPressed: _saveMarkup,
        ),
        const SizedBox(width: 8),
        for (final c in [Colors.red, Colors.green, Colors.yellow, Colors.blue])
          GestureDetector(
            onTap: () => _setColor(c),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                border: Border.all(
                    color: _penColor == c ? Colors.white : Colors.black),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageWidget = widget.entry.url.startsWith('http')
        ? Image.network(widget.entry.url, fit: BoxFit.contain)
        : Image.file(File(widget.entry.url), fit: BoxFit.contain);

    return Scaffold(
      appBar: AppBar(title: const Text('Photo Detail'), actions: [
        _buildToolbar(),
      ]),
      body: Center(
        child: Stack(
          children: [
            Positioned.fill(child: imageWidget),
            if (_markupMode)
              Positioned.fill(
                child: Signature(
                  controller: _controller,
                  backgroundColor: Colors.transparent,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

