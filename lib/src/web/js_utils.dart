import 'dart:js_interop';
import 'package:js/js_util.dart' as js_util;
import 'package:flutter/foundation.dart';

String createBlobUrl(Uint8List data, String mimeType) {
  if (!kIsWeb) {
    throw UnsupportedError('createBlobUrl is only supported on web');
  }
  final blob = js_util.callConstructor(
    js_util.getProperty(js_util.globalThis, 'Blob') as JSObject,
    [js_util.jsify([data]), js_util.jsify({'type': mimeType})],
  );
  return js_util.callMethod(
    js_util.getProperty(js_util.globalThis, 'URL') as JSObject,
    'createObjectURL',
    [blob],
  ) as String;
}

void revokeObjectUrl(String url) {
  if (kIsWeb) {
    js_util.callMethod(
      js_util.getProperty(js_util.globalThis, 'URL') as JSObject,
      'revokeObjectURL',
      [url],
    );
  }
}

void downloadBytes(Uint8List data, String fileName, String mimeType) {
  if (!kIsWeb) return;
  final url = createBlobUrl(data, mimeType);
  final document = js_util.getProperty(js_util.globalThis, 'document') as JSObject;
  final anchor = js_util.callMethod(document, 'createElement', ['a']) as JSObject;
  js_util.setProperty(anchor, 'href', url);
  js_util.setProperty(anchor, 'download', fileName);
  js_util.callMethod(anchor, 'click', []);
  revokeObjectUrl(url);
}

void openLink(String url, {String? target}) {
  if (!kIsWeb) return;
  final document = js_util.getProperty(js_util.globalThis, 'document') as JSObject;
  final anchor = js_util.callMethod(document, 'createElement', ['a']) as JSObject;
  js_util.setProperty(anchor, 'href', url);
  if (target != null) {
    js_util.setProperty(anchor, 'target', target);
  }
  js_util.callMethod(anchor, 'click', []);
}

/// Creates an iframe element for embedding HTML content.
dynamic createIFrame(String src) {
  final document = js_util.getProperty(js_util.globalThis, 'document') as JSObject;
  final iframe = js_util.callMethod(document, 'createElement', ['iframe']) as JSObject;
  js_util.setProperty(iframe, 'src', src);
  js_util.callMethod(
      iframe, 'setAttribute', ['style', 'border: none; width: 100%; height: 100%;']);
  return iframe;
}
