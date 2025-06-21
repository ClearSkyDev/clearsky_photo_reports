import 'dart:typed_data';
import 'dart:js' as js;
import 'package:flutter/foundation.dart';

String createBlobUrl(Uint8List data, String mimeType) {
  if (!kIsWeb) {
    throw UnsupportedError('createBlobUrl is only supported on web');
  }
  final jsArray = js.JsArray<int>.from(data);
  final blob = js.JsObject(js.context['Blob'], [jsArray, js.JsObject.jsify({'type': mimeType})]);
  return js.context['URL'].callMethod('createObjectURL', [blob]) as String;
}

void revokeObjectUrl(String url) {
  if (kIsWeb) {
    js.context['URL'].callMethod('revokeObjectURL', [url]);
  }
}

void downloadBytes(Uint8List data, String fileName, String mimeType) {
  if (!kIsWeb) return;
  final url = createBlobUrl(data, mimeType);
  final document = js.context['document'] as js.JsObject;
  final anchor = document.callMethod('createElement', ['a']);
  anchor['href'] = url;
  anchor['download'] = fileName;
  anchor.callMethod('click');
  revokeObjectUrl(url);
}

void openLink(String url, {String? target}) {
  if (!kIsWeb) return;
  final document = js.context['document'] as js.JsObject;
  final anchor = document.callMethod('createElement', ['a']);
  anchor['href'] = url;
  if (target != null) {
    anchor['target'] = target;
  }
  anchor.callMethod('click');
}

/// Creates an iframe element for embedding HTML content.
dynamic createIFrame(String src) {
  final document = js.context['document'] as js.JsObject;
  final iframe = document.callMethod('createElement', ['iframe']);
  iframe['src'] = src;
  iframe.callMethod('setAttribute', ['style', 'border: none; width: 100%; height: 100%;']);
  return iframe;
}
