import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../levels/level_repository.dart';
import '../store/user_progress_provider.dart';
import '../gameplay/gameplay_screen.dart';
import '../settings/settings_screen.dart';
import '../ads/ad_service.dart';
import '../ads/ad_manager.dart';
import '../levels/level_model.dart';

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
                        Text("${userProgress.totalCoins}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18))
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
                    final unlockCost = level.unlockCost;
                    final hasEnoughCoins = userProgress.totalCoins >= unlockCost;
                    
                    return GestureDetector(
                        onTap: () async {
                            if (isLocked) {
                                // Show popup for locked level
                                _showLockedLevelDialog(context, ref, level, unlockCost, userProgress.totalCoins);
                            } else {
                                await Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => GameplayScreen(levelId: level.id))
                                );
                                // Show ad when returning to home page
                                adService.showInterstitialAd(
                                  onAdDismissed: () {
                                    // Ad dismissed, user is already on home page
                                  },
                                );
                                // The provider will automatically trigger rebuild when state changes
                            }
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
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                        Icon(Icons.lock, color: Colors.white.withOpacity(0.5), size: 32),
                                        if (hasEnoughCoins && level.id == userProgress.maxLevelUnlocked + 1)
                                            Padding(
                                                padding: const EdgeInsets.only(top: 4),
                                                child: Text("Tap!", style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                                            )
                                    ],
                                  )
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

  void _showLockedLevelDialog(BuildContext context, WidgetRef ref, Level level, int unlockCost, int currentCoins) {
    // Preload rewarded ad when dialog opens
    ref.read(adManagerProvider).loadRewarded();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.lock, color: Colors.orange, size: 32),
            const SizedBox(width: 8),
            Text("Level ${level.id} Locked", style: const TextStyle(fontSize: 20)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "You need $unlockCost coins to unlock this level.",
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.monetization_on, color: Colors.yellowAccent),
                const SizedBox(width: 4),
                Text(
                  "You have: $currentCoins coins",
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text("Play Again"),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              // Get ScaffoldMessenger and Navigator before closing dialog
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              
              // Close dialog first
              navigator.pop();
              
              // Show loading message
              scaffoldMessenger.showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      ),
                      SizedBox(width: 12),
                      Text("Loading ad..."),
                    ],
                  ),
                  duration: Duration(seconds: 5),
                ),
              );
              
              // Wait a moment for ad to potentially load
              await Future.delayed(const Duration(milliseconds: 500));
              
              // Show rewarded ad
              ref.read(adManagerProvider).showRewarded(
                (reward) {
                  // Reward earned - add 10 coins and unlock the level
                  ref.read(userProgressProvider.notifier).addCoins(10);
                  ref.read(userProgressProvider.notifier).unlockLevel(level.id);
                  // Hide loading snackbar and show success
                  scaffoldMessenger.hideCurrentSnackBar();
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text("Level ${level.id} unlocked! +10 coins"),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                onAdDismissed: () {
                  // Ad was watched - add 10 coins and unlock the level
                  ref.read(userProgressProvider.notifier).addCoins(10);
                  ref.read(userProgressProvider.notifier).unlockLevel(level.id);
                  // Hide loading snackbar and show success
                  scaffoldMessenger.hideCurrentSnackBar();
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text("Level ${level.id} unlocked! +10 coins"),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                onAdNotReady: () {
                  // Hide loading snackbar and show error with retry option
                  scaffoldMessenger.hideCurrentSnackBar();
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: const Text("Ad failed to load. Please check your internet connection and try again."),
                      duration: const Duration(seconds: 4),
                      backgroundColor: Colors.orange,
                      action: SnackBarAction(
                        label: 'Retry',
                        textColor: Colors.white,
                        onPressed: () {
                          // Retry loading and showing the ad
                          ref.read(adManagerProvider).loadRewarded();
                          // Show the ad again after a short delay
                          Future.delayed(const Duration(seconds: 2), () {
                            ref.read(adManagerProvider).showRewarded(
                              (reward) {
                                ref.read(userProgressProvider.notifier).addCoins(10);
                                ref.read(userProgressProvider.notifier).unlockLevel(level.id);
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(
                                    content: Text("Level ${level.id} unlocked! +10 coins"),
                                    backgroundColor: Colors.green,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                              onAdDismissed: () {
                                ref.read(userProgressProvider.notifier).addCoins(10);
                                ref.read(userProgressProvider.notifier).unlockLevel(level.id);
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(
                                    content: Text("Level ${level.id} unlocked! +10 coins"),
                                    backgroundColor: Colors.green,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                              onAdNotReady: () {
                                scaffoldMessenger.showSnackBar(
                                  const SnackBar(
                                    content: Text("Ad still not ready. Please try again later."),
                                    duration: Duration(seconds: 3),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              },
                            );
                          });
                        },
                      ),
                    ),
                  );
                },
              );
            },
            icon: const Icon(Icons.play_circle_outline),
            label: const Text("Watch Rewarded Ad"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
