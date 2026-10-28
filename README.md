# flutter_in_app_updater

A unified, lightweight, and highly flexible Flutter plugin for handling app update checks. Supports native store update flows (**Google Play In-App Updates** for Android and **StoreKit** for iOS) alongside fully dynamic **custom server-driven API checks** with forced/soft updates, custom UI support, and debug bypass.

[![pub package](https://img.shields.io/pub/v/flutter_in_app_updater.svg)](https://pub.dev/packages/flutter_in_app_updater)
[![license](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

---

## Features

- 📱 **Native Store Support:** Integrates directly with Google Play Core (Android) and StoreKit (iOS).
- ⚡ **Custom API Check:** Compare installed versions against your own server endpoint.
- 🔒 **Server-Driven Forced Updates:** Lock app usage with `forced_update` flags directly controlled by your backend.
- 📝 **Release Notes / Changelog:** Optional dynamic release notes support in update dialogs.
- 🎨 **Flexible UI Options:** Use built-in default dialogs or pass custom UI callbacks (`onUpdateRequired`).
- 🛠️ **Debug Mode Bypass:** Avoid nuisance popups during development with automatic debug detection (`bypassInDebug`).
- 🛑 **Error Handling:** Built-in `onError` catchers for network failures or parsing issues.

---

## Installation

Add `flutter_in_app_updater` to your `pubspec.yaml` file:

```yaml
dependencies:
  flutter_in_app_updater: ^1.0.0
```

Then run:

```bash
flutter pub get
```

---

## Usage

### 1. Custom Server-Driven API Check

This approach lets your backend or firebase remote config decide when updates are required and whether they are forced or optional.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_in_app_updater/flutter_in_app_updater.dart';

void checkForUpdates(BuildContext context) {
  FlutterInAppUpdater.updateViaCustomApi(
    context: context,
    // Provide a callback fetching a JSON payload from your backend
    fetchConfigFromApi: () async {
      // Example API response structure:
      return {
        'min_required_version': '1.2.0',
        'forced_update': true, // Directly controls dismissibility
        'update_url_android': 'https://play.google.com/store/apps/details?id=com.yourcompany.app',
        'update_url_ios': 'https://apps.apple.com/app/id123456789',
        'release_notes': '• Performance enhancements\n• Bug fixes and stability improvements',
      };
    },
    // Set to false during local development if you want to test dialogs in debug mode
    bypassInDebug: false,
    onError: (error) {
      debugPrint("Update check failed: $error");
    },
  );
}
```

#### Custom UI Callback Example
If you want to render your own custom dialog instead of the built-in fallback:

```dart
FlutterInAppUpdater.updateViaCustomApi(
  context: context,
  fetchConfigFromApi: () async => fetchAppConfig(),
  onUpdateRequired: (storeUrl, isForced, releaseNotes) {
    showDialog(
      context: context,
      barrierDismissible: !isForced,
      builder: (context) => PopScope(
        canPop: !isForced,
        child: AlertDialog(
          title: Text(isForced ? 'Critical Update Needed' : 'New Version Ready'),
          content: Text(releaseNotes ?? 'Please update to the latest version.'),
          actions: [
            if (!isForced)
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Later'),
              ),
            ElevatedButton(
              onPressed: () /* Launch storeUrl */,
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  },
);
```

---

### 2. Native Store Update Flow

For standard in-app store updates using official store SDKs (Google Play In-App Update API & iOS SKStoreProductViewController):

```dart
await FlutterInAppUpdater.updateNative(
  immediateAndroid: true, // Use immediate (blocking) flow on Android
  iosAppStoreId: '123456789', // Your App Store numeric ID
);
```

---

## API Reference

### `updateViaCustomApi` Parameters

| Parameter | Type | Mandatory | Description |
| :--- | :--- |:----------| :--- |
| `context` | `BuildContext` | Yes       | Context required to present the update dialog. |
| `fetchConfigFromApi` | `Future<Map<String, dynamic>> Function()` | Yes       | Async callback returning the update configuration map. |
| `onUpdateRequired` | `Function(String storeUrl, bool isForced, String? releaseNotes)?` | No        | Custom UI renderer. Overrides default dialog if provided. |
| `onError` | `Function(Object error)?` | No        | Callback invoked on API or parsing failures. |
| `iosAppStoreId` | `String?` | No        | App Store ID used if `update_url_ios` is omitted in payload. |
| `bypassInDebug` | `bool` | No        | Defaults to `true`. Ignores update checks during `kDebugMode`. |

---

## Important Platform Notes

- **Android Play Core API:** Native updates require your app to be published on a Google Play track (Internal Testing, Closed Testing, or Production). Native updates will return error `-6` when tested via local `flutter run` side-loaded APKs.
- **iOS StoreKit:** Native modal presentation requires a valid `iosAppStoreId`.

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---
