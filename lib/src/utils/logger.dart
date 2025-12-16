import 'package:flutter/foundation.dart';

class Logger {
  static void log(String message) {
    // Only log in debug mode - automatically stripped in release builds
    if (kDebugMode) {
      debugPrint('[Worbix] $message');
    }
  }
}
