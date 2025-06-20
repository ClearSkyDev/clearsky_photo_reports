import 'dart:convert';

/// Displays the generated report HTML across Flutter platforms.
///
/// * Web: uses `package:web/web.dart` to create an `IFrameElement` which is
///   registered with `ui.platformViewRegistry` so it can be embedded
///   in the widget tree via `HtmlElementView`.
/// * Mobile: uses the `webview_flutter` plugin. The HTML string is
///   converted to a base64 data URI and loaded as local content.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Conditionally import webview_flutter only if not web
// ignore: uri_does_not_exist
import 'package:webview_flutter/webview_flutter.dart'
    if (dart.library.html) 'webview_stub.dart';

// Only imported on web for HtmlElementView
import 'package:web/web.dart' as html;
import 'dart:ui' as ui
    if (dart.library.html) 'dart:ui';

class ReportPreviewWebView extends StatefulWidget {
  final String html;
  final VoidCallback onExportPdf;
  final VoidCallback? onEditLabels;

  const ReportPreviewWebView({
    super.key,
    required this.html,
    required this.onExportPdf,
    this.onEditLabels,
  });

  @override
  State<ReportPreviewWebView> createState() => _ReportPreviewWebViewState();
}

class _ReportPreviewWebViewState extends State<ReportPreviewWebView> {
  String? _viewId;
  String? _blobUrl;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _viewId = 'report-preview-${DateTime.now().millisecondsSinceEpoch}';
      // ignore: undefined_prefixed_name
      ui.platformViewRegistry.registerViewFactory(
        _viewId!,
        (int viewId) {
          final iframe = html.IFrameElement()
            ..src = _blobUrl!
            ..style.border = 'none'
            ..style.width = '100%'
            ..style.height = '100%';
          return iframe;
        },
      );
      // Create a Blob URL for the HTML content
      final blob = html.Blob([widget.html], 'text/html');
      _blobUrl = html.Url.createObjectUrlFromBlob(blob);
    }
  }

  @override
  void dispose() {
    if (_blobUrl != null) {
      html.Url.revokeObjectUrl(_blobUrl!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget preview;
    if (kIsWeb) {
      preview = HtmlElementView(viewType: _viewId!);
    } else {
      preview = Builder(
        builder: (context) {
          return WebView(
            initialUrl: Uri.dataFromString(
              widget.html,
              mimeType: 'text/html',
              encoding: utf8,
              base64: true,
            ).toString(),
            javascriptMode: JavaScriptMode.unrestricted,
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Preview Report')),
      body: Column(
        children: [
          Expanded(child: preview),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (widget.onEditLabels != null)
                  ElevatedButton(
                    onPressed: widget.onEditLabels,
                    child: const Text('Edit Labels'),
                  ),
                ElevatedButton(
                  onPressed: widget.onExportPdf,
                  child: const Text('Export PDF'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
