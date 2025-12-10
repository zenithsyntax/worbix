import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'user_progress_model.dart';

const String kProgressKey = 'progress_data';

class UserProgressNotifier extends Notifier<UserProgress> {
  late SharedPreferences _prefs;

  @override
  UserProgress build() {
    return const UserProgress();
  }
  
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final String? stored = _prefs.getString(kProgressKey);
    
    if (stored != null) {
        try {
            final jsonMap = json.decode(stored);
            state = UserProgress.fromJson(jsonMap);
        } catch (e) {
            debugPrint("Error loading progress: $e");
            state = const UserProgress();
        }
    } else {
        state = const UserProgress();
    }
  }

  Future<void> _save() async {
    await _prefs.setString(kProgressKey, json.encode(state.toJson()));
  }

  Future<void> unlockLevel(int levelId) async {
    if (levelId > state.maxLevelUnlocked) {
        state = state.copyWith(maxLevelUnlocked: levelId);
        await _save();
    }
  }

  Future<void> addCoins(int amount) async {
    final newCoins = state.totalCoins + amount;
    state = state.copyWith(totalCoins: newCoins);
    await _save();
  }
  
  Future<void> spendCoins(int amount) async {
    if (state.totalCoins >= amount) {
        final newCoins = state.totalCoins - amount;
        state = state.copyWith(totalCoins: newCoins);
        await _save();
    }
  }
  
  Future<void> markQuestionCompleted({
      required int levelId, 
      required int questionId, 
      required int coinsEarned,
      bool allowReplayCoins = false, // If true, allow earning coins again on replay
  }) async {
      // Update coins (always add coins, even on replay if allowReplayCoins is true)
      final newTotalCoins = state.totalCoins + coinsEarned;
      
      // Update persistent tracker
      // If we used a Map<int, List<int>> where key is LevelID
      final Map<int, List<int>> newCompleted = Map.from(state.completedQuestions);
      final currentList = newCompleted[levelId] ?? [];
      
      // Only add to completed list if not already there
      if (!currentList.contains(questionId)) {
         newCompleted[levelId] = [...currentList, questionId];
      }
      
      // Correct flow:
      state = state.copyWith(
          totalCoins: newTotalCoins,
          completedQuestions: newCompleted,
          lastPlayedLevelId: levelId,
      );
      await _save();
      
      // Auto-unlock check (based on total coins earned from all questions)
      await checkAutoUnlock();
  }
  
  // Update last played status without completing (e.g. valid exit)
  Future<void> savePosition(int levelId, int questionIndex) async {
      state = state.copyWith(
          lastPlayedLevelId: levelId,
          lastPlayedQuestionIndex: questionIndex,
      );
      await _save();
  }

  Future<void> setInstructionsSeen() async {
      state = state.copyWith(instructionsSeen: true);
      await _save();
  }
  
  Future<void> setSoundEnabled(bool enabled) async {
      state = state.copyWith(soundEnabled: enabled);
      await _save();
  }
  
  Future<void> checkAutoUnlock() async {
      // Logic: Next level cost = (id - 1) * 50.
      // e.g. Level 2 cost 50. Level 3 cost 100.
      // We check if currentCoins >= cost of (maxLevel + 1).
      
      int currentMax = state.maxLevelUnlocked;
      bool changed = false;
      
      // Safety break to prevent infinite loops if cost is 0 or logic creates issues, though cost increases.
      for (int i = 0; i < 100; i++) {
           int nextLevelId = currentMax + 1;
           int cost = (nextLevelId - 1) * 50;
           
           if (state.totalCoins >= cost) {
               currentMax = nextLevelId;
               changed = true;
           } else {
               break;
           }
      }
      
      if (changed) {
          state = state.copyWith(maxLevelUnlocked: currentMax);
          await _save();
      }
  }
  
  // Helper not to confuse addCoins parameter name
  int newCoinsEarned({required int amount}) => state.totalCoins + amount; // Just a helper
}

final userProgressProvider = NotifierProvider<UserProgressNotifier, UserProgress>(UserProgressNotifier.new);

final initUserProgressProvider = FutureProvider<void>((ref) async {
  await ref.read(userProgressProvider.notifier).init();
});
