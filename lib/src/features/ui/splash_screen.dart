import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../levels/level_repository.dart';
import '../store/user_progress_provider.dart';
import 'home_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      // Initialize Level Repository
      await ref.read(levelRepositoryProvider).init();
      // Initialize User Progress
      await ref.read(initUserProgressProvider.future);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      // Handle error - show retry option to user
      if (kDebugMode) {
        debugPrint('Init error: $e');
      }
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to load app data. Please try again.';
        });
      }
    }
  }

  Future<void> _retry() async {
    setState(() {
      _hasError = false;
      _errorMessage = null;
    });
    await _init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/worbix-logo.png',
              height: 170,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20),
            if (_hasError) ...[
              Text(
                _errorMessage ?? 'An error occurred',
                style: const TextStyle(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _retry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ] else
              const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
