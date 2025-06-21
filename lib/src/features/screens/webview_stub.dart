import 'package:flutter/widgets.dart';

/// Stub classes mirroring the webview_flutter API when the plugin is
/// unavailable (e.g. on web). These simply render nothing.
class WebViewController {
  void loadRequest(Uri uri) {}
  void loadHtmlString(String html) {}
  void setJavaScriptMode(JavaScriptMode mode) {}
}

class WebViewWidget extends StatelessWidget {
  final WebViewController controller;
  const WebViewWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

enum JavaScriptMode { unrestricted, disabled }
