import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'src/app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Ads
  // TODO: Open boxes if needed eagerly, or lazily in repositories
  
  // Initialize Ads
  // We don't await this so it doesn't block startup
  MobileAds.instance.initialize();

  runApp(const ProviderScope(child: WorbixApp()));
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(dynamic message) async {
  // Dummy handler to prevent crash if native code calls it unexpectedly
  print("Ignoring background message: $message");
}
