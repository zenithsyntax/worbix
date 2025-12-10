class Logger {
  static void log(String message) {
    // In production, use a proper logger package or tree shaking
    print('[Worbix] $message');
  }
}
