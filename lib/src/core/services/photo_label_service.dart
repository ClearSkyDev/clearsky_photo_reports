import 'dart:io';
import 'package:google_ml_kit/google_ml_kit.dart';

class PhotoLabelService {
  static Future<String> suggestLabel(String imagePath, String sectionPrefix) async {
    final inputImage = InputImage.fromFile(File(imagePath));
    final labeler = GoogleMlKit.vision
        .imageLabeler(ImageLabelerOptions(confidenceThreshold: 0.6));

    final labels = await labeler.processImage(inputImage);
    await labeler.close();

    if (labels.isEmpty) return "$sectionPrefix – Unrecognized";

    final top = labels.first.label;
    return "$sectionPrefix – $top";
  }
}
