import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../levels/level_repository.dart';
import '../store/user_progress_provider.dart';
import '../gameplay/gameplay_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final levelsAsync = ref.watch(levelsProvider);
    final userProgress = ref.watch(userProgressProvider);
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        elevation: 0,
        title: Text("Worbix", style: theme.textTheme.displaySmall?.copyWith(color: Colors.white, fontSize: 32)),
        centerTitle: true,
        actions: [
            Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                child: Row(
                    children: [
                        const Icon(Icons.monetization_on, color: Colors.yellowAccent),
                        const SizedBox(width: 4),
                        Text("${userProgress.coins}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18))
                    ],
                )
            ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
            IconButton(
                icon: const Icon(Icons.settings, color: Colors.white),
                onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
                },
            )
        ],
      ),
      body: Container(
        color: theme.colorScheme.surface,
        child: levelsAsync.when(
            data: (levels) {
              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(20, 120, 20, 20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, // Bigger icons for kids
                  childAspectRatio: 1,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                ),
                itemCount: levels.length,
                itemBuilder: (context, index) {
                    final level = levels[index];
                    final isLocked = level.id > userProgress.maxLevelUnlocked;
                    
                    return GestureDetector(
                        onTap: isLocked ? null : () {
                            Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => GameplayScreen(levelId: level.id))
                            );
                        },
                        child: Container(
                            decoration: BoxDecoration(
                                color: isLocked ? Colors.black26 : Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withOpacity(0.8), width: 4),
                                boxShadow: [
                                    BoxShadow(color: Colors.black.withOpacity(isLocked ? 0.1 : 0.2), blurRadius: 8, offset: const Offset(0,4))
                                ]
                            ),
                            alignment: Alignment.center,
                            child: isLocked 
                                ? Icon(Icons.lock, color: Colors.white.withOpacity(0.5), size: 32) 
                                : Text("${level.id}", style: theme.textTheme.headlineLarge?.copyWith(
                                    color: theme.colorScheme.primary, fontWeight: FontWeight.bold
                                  )),
                        ),
                    ).animate(delay: (50 * index).ms).scale(duration: 400.ms, curve: Curves.easeOutBack).fade();
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
            error: (err, st) => Center(child: Text("Error loading levels", style: TextStyle(color: Colors.white))),
        ),
      ),
    );
  }
}
