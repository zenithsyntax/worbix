import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'src/app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  // TODO: Open boxes if needed eagerly, or lazily in repositories
  
  // Initialize Ads
  // We don't await this so it doesn't block startup
  MobileAds.instance.initialize();

  runApp(const ProviderScope(child: WorbixApp()));
}
