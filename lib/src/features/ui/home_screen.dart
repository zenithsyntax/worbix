import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../levels/level_map_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Worbix",
                style: TextStyle(fontSize: 64, fontWeight: FontWeight.bold, color: Colors.orange),
              ),
              const SizedBox(height: 48),
              _MenuButton(
                title: "Play",
                color: Colors.green,
                onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LevelMapScreen()),
                    );
                },
              ),
              const SizedBox(height: 16),
              _MenuButton(
                title: "Store",
                color: Colors.purple,
                onPressed: () {},
              ),
              const SizedBox(height: 16),
              _MenuButton(
                title: "Settings",
                color: Colors.blue,
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final String title;
  final VoidCallback onPressed;
  final Color color;

  const _MenuButton({required this.title, required this.onPressed, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
        ),
        onPressed: onPressed,
        child: Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
