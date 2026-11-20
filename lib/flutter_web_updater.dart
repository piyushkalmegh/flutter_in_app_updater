import 'package:web/web.dart' as web;

class WebUpdater {
  /// Web-specific implementation using modern package:web
  static void reloadBrowser() {
    web.window.location.reload();
  }
}
