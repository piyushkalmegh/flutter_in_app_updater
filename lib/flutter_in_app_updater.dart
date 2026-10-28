import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// A unified plugin to handle native store updates and custom server-driven API checks.
class FlutterInAppUpdater {
  static const MethodChannel _channel = MethodChannel('flutter_in_app_updater');

  /// 1. Default Native Flow (Google Play In-App Updates & iOS StoreKit)
  static Future<void> updateNative({
    bool immediateAndroid = true,
    required String iosAppStoreId,
  }) async {
    try {
      if (Platform.isAndroid) {
        await _channel.invokeMethod('updateAndroid', {'immediate': immediateAndroid});
      } else if (Platform.isIOS) {
        await _channel.invokeMethod('updateIos', {'appStoreId': iosAppStoreId});
      }
    } catch (e) {
      debugPrint("Native update failed: $e");
    }
  }

  /// 2. Custom API Flow Controlled Directly by Server JSON
  /// Expected JSON fields returned by [fetchConfigFromApi]:
  /// - `min_required_version` (String, e.g., "1.0.2")
  /// - `forced_update` (bool, e.g., true/false - controlled by server)
  /// - `update_url_android` (String)
  /// - `update_url_ios` (String, optional)
  /// - `release_notes` (String, optional)
  static Future<void> updateViaCustomApi({
    required BuildContext context,
    required Future<Map<String, dynamic>> Function() fetchConfigFromApi,
    void Function(String storeUrl, bool isForced, String? releaseNotes)? onUpdateRequired,
    void Function(Object error)? onError,
    String? iosAppStoreId,
    bool bypassInDebug = true,
  }) async {
    try {
      if (bypassInDebug && kDebugMode) {
        debugPrint("MyInAppUpdate: Bypassing update check because app is running in DEBUG mode.");
        return;
      }

      final data = await fetchConfigFromApi();

      String minVersion = data['min_required_version'] ?? '1.0.0';
      bool isForced = data['forced_update'] ?? false;
      String? releaseNotes = data['release_notes'];
      String storeUrlAndroid = data['update_url_android'] ?? '';
      String storeUrlIos = data['update_url_ios'] ?? (iosAppStoreId != null ? 'https://apps.apple.com/app/id$iosAppStoreId' : '');

      final packageInfo = await PackageInfo.fromPlatform();
      String currentVersion = packageInfo.version;

      if (_isVersionOlder(currentVersion, minVersion)) {
        String targetUrl = Platform.isAndroid ? storeUrlAndroid : storeUrlIos;

        if (onUpdateRequired != null) {
          onUpdateRequired(targetUrl, isForced, releaseNotes);
        } else {
          _showDefaultUpdateDialog(context, storeUrl: targetUrl, isForced: isForced, releaseNotes: releaseNotes);
        }
      }
    } catch (e) {
      debugPrint("Custom API update check failed: $e");
      if (onError != null) {
        onError(e);
      }
    }
  }

  static bool _isVersionOlder(String current, String minimum) {
    List<int> currParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    List<int> minParts = minimum.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    for (int i = 0; i < 3; i++) {
      int c = i < currParts.length ? currParts[i] : 0;
      int m = i < minParts.length ? minParts[i] : 0;
      if (c < m) return true;
      if (c > m) return false;
    }
    return false;
  }

  /// Built-in fallback dialog responsive to the server's `forced_update` flag
  static void _showDefaultUpdateDialog(
      BuildContext context, {
        required String storeUrl,
        required bool isForced,
        String? releaseNotes,
      }) {
    showDialog(
      context: context,
      barrierDismissible: !isForced,
      builder: (context) => PopScope(
        canPop: !isForced,
        child: AlertDialog(
          title: Text(isForced ? 'Update Required' : 'New Update Available'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isForced
                  ? 'A mandatory update is available. Please update the app to proceed.'
                  : 'A newer version of the app is available.'),
              if (releaseNotes != null && releaseNotes.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text("What's New:", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(releaseNotes, style: const TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            ],
          ),
          actions: [
            if (!isForced)
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Later'),
              ),
            ElevatedButton(
              onPressed: () async {
                final uri = Uri.parse(storeUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: const Text('Update Now'),
            ),
          ],
        ),
      ),
    );
  }
}