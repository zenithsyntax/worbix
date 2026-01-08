import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'src/app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock screen orientation to portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Configure ad request settings for COPPA compliance
  // Required when targeting children under 13
  // This global configuration applies to ALL ads (banner, interstitial, rewarded)
  // in both home screen and gameplay screen automatically
  final configuration = RequestConfiguration(
    tagForChildDirectedTreatment: TagForChildDirectedTreatment.no,
    tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.no,
    maxAdContentRating: MaxAdContentRating.pg,
  );
  MobileAds.instance.updateRequestConfiguration(configuration);

  // Initialize Ads
  // We don't await this so it doesn't block startup
  await MobileAds.instance.initialize();

  runApp(const ProviderScope(child: WorbixApp()));
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(dynamic message) async {
  // Dummy handler to prevent crash if native code calls it unexpectedly
  // Only log in debug mode
  if (kDebugMode) {
    debugPrint("Ignoring background message: $message");
  }
}
