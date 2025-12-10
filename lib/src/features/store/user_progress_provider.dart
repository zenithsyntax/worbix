import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Simple data class
class UserProgress {
  final int maxLevelUnlocked;
  final int coins;

  const UserProgress({
    this.maxLevelUnlocked = 1,
    this.coins = 0,
  });
  
  UserProgress copyWith({int? maxLevelUnlocked, int? coins}) {
    return UserProgress(
      maxLevelUnlocked: maxLevelUnlocked ?? this.maxLevelUnlocked,
      coins: coins ?? this.coins,
    );
  }
}

// Hive keys
const String kUserProgressBox = 'user_progress';
const String kMaxLevelKey = 'max_level';
const String kCoinsKey = 'coins';

class UserProgressNotifier extends Notifier<UserProgress> {
  late Box _box;

  @override
  UserProgress build() {
    // We assume Hive.initFlutter() is called in main
    // We open box synchronously if possible, or we should have opened it in main
    // But Notifier build is synchronous.
    // Ideally we use FutureProvider or AsyncNotifier.
    // For simplicity, let's use AsyncNotifier or ensure box is open.
    // Let's use AsyncNotifier to be safe.
    
    // However, for game UI we want synchronous access if possible to avoid flickering.
    // Let's assume loading is fast.
    return const UserProgress(); 
  }
  
  Future<void> init() async {
    _box = await Hive.openBox(kUserProgressBox);
    final int maxLvl = _box.get(kMaxLevelKey, defaultValue: 1);
    final int coins = _box.get(kCoinsKey, defaultValue: 0);
    state = UserProgress(maxLevelUnlocked: maxLvl, coins: coins);
  }

  Future<void> unlockLevel(int levelId) async {
    if (levelId > state.maxLevelUnlocked) {
        state = state.copyWith(maxLevelUnlocked: levelId);
        await _box.put(kMaxLevelKey, levelId);
    }
  }

  Future<void> addCoins(int amount) async {
    final newCoins = state.coins + amount;
    state = state.copyWith(coins: newCoins);
    await _box.put(kCoinsKey, newCoins);
  }
  
  Future<void> spendCoins(int amount) async {
    if (state.coins >= amount) {
        final newCoins = state.coins - amount;
        state = state.copyWith(coins: newCoins);
        await _box.put(kCoinsKey, newCoins);
    }
  }
}

// Ensure we use AsyncNotifier or load explicitly.
// Let's use a simpler approach: A wrapper provider that initializes.
final userProgressProvider = NotifierProvider<UserProgressNotifier, UserProgress>(UserProgressNotifier.new);

// Initialization provider
final initUserProgressProvider = FutureProvider<void>((ref) async {
  await ref.read(userProgressProvider.notifier).init();
});
