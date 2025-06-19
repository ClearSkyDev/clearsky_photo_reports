import 'dart:io';

import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

import '../models/photo_entry.dart';
import '../services/tts_service.dart';

class PhotoDetailScreen extends StatefulWidget {
  final PhotoEntry entry;
  const PhotoDetailScreen({super.key, required this.entry});

  @override
  State<PhotoDetailScreen> createState() => _PhotoDetailScreenState();
}

class _PhotoDetailScreenState extends State<PhotoDetailScreen> {
  late SignatureController _controller;
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
    if (TtsService.instance.settings.handsFree) {
      TtsService.instance.speak(widget.entry.label);
    }
  }

  @override
  void dispose() {
    TtsService.instance.stop();
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
    img.compositeImage(baseImage, resizedOverlay);

    final dir = p.dirname(file.path);
    final newPath =
        p.join(dir, '${p.basenameWithoutExtension(file.path)}_marked.jpg');
    final newFile = File(newPath);
    await newFile.writeAsBytes(img.encodeJpg(baseImage));
    setState(() {
      widget.entry.originalUrl ??= widget.entry.url;
      widget.entry.url = newFile.path;
    });
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  void _setColor(Color color) {
    setState(() {
      _penColor = color;
      final points = _controller.points;
      _controller.dispose();
      _controller = SignatureController(
        points: points,
        penStrokeWidth: 3,
        penColor: _penColor,
        exportBackgroundColor: Colors.transparent,
      );
    });
  }

  Widget _buildToolbar() {
    if (!_markupMode) {
      return IconButton(
        icon: const Icon(Icons.brush),
        tooltip: 'Start Markup',
        onPressed: () => setState(() => _markupMode = true),
      );
    }
    const colorNames = ['red', 'green', 'yellow', 'blue'];
    final colors = [Colors.red, Colors.green, Colors.yellow, Colors.blue];
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Cancel Markup',
          onPressed: () {
            setState(() {
              _markupMode = false;
              _controller.clear();
            });
          },
        ),
        IconButton(
          icon: const Icon(Icons.delete),
          tooltip: 'Clear Markup',
          onPressed: _controller.clear,
        ),
        IconButton(
          icon: const Icon(Icons.save),
          tooltip: 'Save Markup',
          onPressed: _saveMarkup,
        ),
        const SizedBox(width: 8),
        for (int i = 0; i < 4; i++)
          GestureDetector(
            onTap: () => _setColor(colors[i]),
            child: Semantics(
              label: 'Select ${colorNames[i]} pen color',
              button: true,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: colors[i],
                  shape: BoxShape.circle,
                  border: Border.all(
                      color:
                          _penColor == colors[i] ? Colors.white : Colors.black),
                ),
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
        IconButton(
          icon: const Icon(Icons.volume_up),
          tooltip: 'Speak Label',
          onPressed: () => TtsService.instance.speak(widget.entry.label),
        ),
        IconButton(
          icon: const Icon(Icons.pause),
          tooltip: 'Pause Speech',
          onPressed: () => TtsService.instance.pause(),
        ),
        IconButton(
          icon: const Icon(Icons.stop),
          tooltip: 'Stop Speech',
          onPressed: () => TtsService.instance.stop(),
        ),
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
