import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Crops [file] to a square aspect ratio (1:1).
/// Returns the cropped image as a new [XFile].
/// If cropping fails, the original [file] is returned.
class SquareCropper {
  SquareCropper._();

  static Future<XFile> crop(XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return file;
      final size = image.width < image.height ? image.width : image.height;
      final offsetX = (image.width - size) ~/ 2;
      final offsetY = (image.height - size) ~/ 2;
      final cropped = img.copyCrop(
        image,
        x: offsetX,
        y: offsetY,
        width: size,
        height: size,
      );
      final tempDir = await getTemporaryDirectory();
      final path = p.join(
        tempDir.path,
        'crop_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      final jpg = img.encodeJpg(cropped);
      await File(path).writeAsBytes(jpg);
      return XFile(path);
    } catch (_) {
      return file;
    }
  }
}
