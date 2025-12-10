import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'src/app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configure test device IDs for development
  if (kDebugMode) {
    final configuration = RequestConfiguration(
      testDeviceIds: ['D8A458A384886F4C41F86ED2A2C2F8D3'], // Your test device ID
    );
    MobileAds.instance.updateRequestConfiguration(configuration);
  }
  
  // Initialize Ads
  // We don't await this so it doesn't block startup
  await MobileAds.instance.initialize();

  runApp(const ProviderScope(child: WorbixApp()));
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(dynamic message) async {
  // Dummy handler to prevent crash if native code calls it unexpectedly
  print("Ignoring background message: $message");
}
