import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class EnterpriseInstaller {
  static const MethodChannel _channel = MethodChannel('flutter_in_app_updater');

  /// Cleans up any leftover update APKs from previous sessions.
  static Future<void> clearOldApks() async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/enterprise_update.apk');
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  /// Downloads and installs an enterprise APK with built-in or custom progress dialog.
  ///
  /// - [forcedUpdate]: If true, prevents the user from dismissing the dialog.
  /// - [bypassInDebug]: If true, skips showing/downloading when running in debug mode.
  /// - [progressBuilder]: Optional custom widget builder if the developer wants their own UI.
  static Future<void> downloadAndInstall({
    required BuildContext context,
    required String apkUrl,
    bool forcedUpdate = false,
    bool bypassInDebug = true,
    Widget Function(BuildContext context, double progress)? progressBuilder,
  }) async {
    if (!Platform.isAndroid) {
      throw UnsupportedError(
          'Enterprise direct APK installation is only supported on Android.');
    }

    // Handle debug bypass check (preserving your core USP)
    bool isInDebugMode = false;
    assert(() {
      isInDebugMode = true;
      return true;
    }());

    if (bypassInDebug && isInDebugMode) {
      debugPrint('EnterpriseInstaller: Bypassing update check in debug mode.');
      return;
    }

    ValueNotifier<double> progressNotifier = ValueNotifier(0.0);
    bool isDownloading = true;

    // Show dialog (either default or custom)
    showDialog(
      context: context,
      barrierDismissible: !forcedUpdate,
      builder: (dialogContext) {
        return PopScope(
          // Prevent hardware back button if it's a mandatory update
          canPop: !forcedUpdate,
          child: AlertDialog(
            title: const Text('Downloading Update'),
            content: ValueListenableBuilder<double>(
              valueListenable: progressNotifier,
              builder: (context, progress, child) {
                if (progressBuilder != null) {
                  return progressBuilder(context, progress);
                }
                // Default Built-in UI
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LinearProgressIndicator(value: progress),
                    const SizedBox(height: 16),
                    Text('${(progress * 100).toStringAsFixed(0)}% completed'),
                    if (forcedUpdate) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'This is a required update.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ]
                  ],
                );
              },
            ),
          ),
        );
      },
    );

    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(apkUrl));
      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw HttpException(
            'Server returned status code: ${response.statusCode}');
      }

      final totalBytes = response.contentLength ?? -1;
      int downloadedBytes = 0;

      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/enterprise_update.apk';
      final file = File(filePath);
      final sink = file.openWrite();

      await for (final chunk in response.stream) {
        downloadedBytes += chunk.length;
        sink.add(chunk);
        if (totalBytes > 0) {
          progressNotifier.value = downloadedBytes / totalBytes;
        }
      }

      await sink.close();

      // Close the progress dialog safely
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      // Trigger native installation
      await _installApkLocally(filePath);
    } catch (e) {
      if (context.mounted && isDownloading) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      rethrow;
    } finally {
      client.close();
    }
  }

  static Future<void> _installApkLocally(String filePath) async {
    try {
      await _channel.invokeMethod('installApk', {'path': filePath});
    } on PlatformException catch (e) {
      throw PlatformException(
        code: e.code,
        message: 'Failed to trigger native APK installation: ${e.message}',
      );
    }
  }
}
