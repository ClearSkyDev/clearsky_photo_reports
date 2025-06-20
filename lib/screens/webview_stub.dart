import 'package:flutter/widgets.dart';

/// Stub for the WebView widget when the webview_flutter plugin is
/// unavailable (e.g. on web). This simply displays a placeholder
/// indicating that WebView is not supported.
class WebView extends StatelessWidget {
  final String? initialUrl;
  final JavascriptMode javascriptMode;

  const WebView({
    super.key,
    this.initialUrl,
    this.javascriptMode = JavascriptMode.unrestricted,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

/// Minimal enum matching the API from webview_flutter.
enum JavascriptMode { unrestricted, disabled }
