import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Utility for saving and loading a default inspector signature on the device.
class SignatureStorage {
  static const String _fileName = 'savedSignature.png';

  static Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, _fileName));
  }

  /// Save [bytes] as the default signature image.
  static Future<void> save(Uint8List bytes) async {
    final file = await _file();
    await file.writeAsBytes(bytes, flush: true);
  }

  /// Load the saved signature image if it exists.
  static Future<Uint8List?> load() async {
    final file = await _file();
    if (await file.exists()) {
      return await file.readAsBytes();
    }
    return null;
  }

  /// Delete any stored signature.
  static Future<void> clear() async {
    final file = await _file();
    if (await file.exists()) {
      await file.delete();
    }
  }
}
