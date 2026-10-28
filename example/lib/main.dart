import 'package:flutter/material.dart';
import 'package:flutter_in_app_updater/flutter_in_app_updater.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. MaterialApp is at the absolute root
    return const MaterialApp(
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();

    // 2. This context now correctly has MaterialApp and MaterialLocalizations as ancestors
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterInAppUpdater.updateViaCustomApi(
        context: context,
        fetchConfigFromApi: () async {
          return {
            'min_required_version': '9.9.9', // Triggers update dialog
            'forced_update': false,
            'update_url_android': 'https://play.google.com/store/apps/details?id=your.package.name',
            'release_notes': 'Testing custom update dialog locally.',
          };
        },
        bypassInDebug: false, // Allows testing in debug mode
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plugin Example')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            /*FlutterInAppUpdater.updateNative(
                immediateAndroid: true,
                iosAppStoreId: '123456789',
              );*/

            FlutterInAppUpdater.updateViaCustomApi(
              context: context,
              fetchConfigFromApi: () async {
                return {
                  'min_required_version': '1.0.1',
                  'forced_update': false,
                  'update_url_android': 'https://play.google.com/store/apps/details?id=your.package.name',
                  'release_notes': 'Testing manual trigger.',
                };
              },
              bypassInDebug: false,
            );
          },
          child: const Text('Trigger Custom Update Check'),
        ),
      ),
    );
  }
}