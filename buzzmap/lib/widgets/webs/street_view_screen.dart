import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
// For Android-specific features
import 'package:webview_flutter_android/webview_flutter_android.dart';
// For iOS-specific features
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class StreetViewScreen extends StatefulWidget {
  final double latitude;
  final double longitude;

  const StreetViewScreen({
    Key? key,
    required this.latitude,
    required this.longitude,
  }) : super(key: key);

  @override
  _StreetViewScreenState createState() => _StreetViewScreenState();
}

class _StreetViewScreenState extends State<StreetViewScreen> {
  late final WebViewController _webViewController;

  @override
  void initState() {
    super.initState();

    // Create the WebViewController
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final WebViewController controller =
        WebViewController.fromPlatformCreationParams(params);

    // Initialize the controller
    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    _webViewController = controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(
          "https://www.google.com/maps/@${widget.latitude},${widget.longitude},3a,75y,90h,65t/data=!3m6!1e1!3m4!1s-4uHrHv1w4sI%2FVPmQhNkI3AI%2FAAAAAAAAA4A%2FzZ2wzYQJQ7Y!2e4!3e11!6s%2F%2Flh5.googleusercontent.com%2F-4uHrHv1w4sI%2FVPmQhNkI3AI%2FAAAAAAAAA4A%2FzZ2wzYQJQ7Y%2Fw203-h100-k-no-pi-0-ya7.941176-ro-0-fo100%2F!7i8704!8i4352"));

    // Set the platform
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      (controller.platform as WebKitWebViewController)
          .setAllowsBackForwardNavigationGestures(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Street View'),
      ),
      body: WebViewWidget(
        controller: _webViewController,
      ),
    );
  }
}
