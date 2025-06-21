import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';

import '../models/saved_report.dart';
import 'tts_service.dart';

/// Service for building narrated slideshow videos from inspection photos.
class VideoReportService {
  VideoReportService._();
  static final VideoReportService instance = VideoReportService._();

  /// Generates a video report using [report]'s labeled photos. The optional
  /// [musicPath] will be mixed with the narration audio if provided.
  Future<File> generateVideoReport(
    SavedReport report, {
    String? musicPath,
  }) async {
    final temp = await getTemporaryDirectory();
    final slideList = File(p.join(temp.path, 'slides.txt'));
    final audioList = <String>[];
    final slides = StringBuffer();
    for (final struct in report.structures) {
      for (final entry in struct.sectionPhotos.entries) {
        for (final photo in entry.value) {
          slides
            ..writeln("file '${photo.photoUrl}'")
            ..writeln('duration 3');
          final label = photo.label.isNotEmpty ? photo.label : entry.key;
          final slideIndex = audioList.length;
          final audio = await TtsService.instance
              .synthesizeClip(label, name: 'slide_\${slideIndex}.mp3');
          audioList.add(audio.path);
        }
      }
    }
    if (slides.isNotEmpty) {
      final last =
          report.structures.last.sectionPhotos.values.last.last.photoUrl;
      slides.writeln("file '$last'");
    }
    await slideList.writeAsString(slides.toString());

    final audioListFile = File(p.join(temp.path, 'audio.txt'));
    final audioBuf = StringBuffer();
    for (final a in audioList) {
      audioBuf.writeln("file '$a'");
    }
    await audioListFile.writeAsString(audioBuf.toString());

    final voicePath = p.join(temp.path, 'voice.mp3');
    await FFmpegKit.execute(
      "-y -f concat -safe 0 -i ${audioListFile.path} -c copy $voicePath",
    );

    final output = File(p.join(temp.path,
        'video_report_${DateTime.now().millisecondsSinceEpoch}.mp4'));
    final cmd = musicPath == null
        ? "-y -f concat -safe 0 -i ${slideList.path} -vf fps=25 -pix_fmt yuv420p -i $voicePath -shortest ${output.path}"
        : "-y -f concat -safe 0 -i ${slideList.path} -vf fps=25 -pix_fmt yuv420p -i $voicePath -i $musicPath -filter_complex '[1:a][2:a]amix=inputs=2:duration=longest' -shortest ${output.path}";
    await FFmpegKit.execute(cmd);
    return output;
  }

  /// Convenience helper to return the generated video as bytes.
  Future<Uint8List> generateVideoReportBytes(
    SavedReport report, {
    String? musicPath,
  }) async {
    final file = await generateVideoReport(report, musicPath: musicPath);
    final bytes = await file.readAsBytes();
    return Uint8List.fromList(bytes);
  }
}
