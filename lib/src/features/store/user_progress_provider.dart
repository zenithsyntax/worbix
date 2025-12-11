import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'user_progress_model.dart';
import '../levels/level_repository.dart';

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
      
      // Check if next level should unlock (10 questions completed + enough coins)
      await _checkAndUnlockNextLevel(levelId);
      
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
      // Logic: Next level cost = unlockCoins from level data.
      // We check if currentCoins >= unlockCoins of (maxLevel + 1).
      // Also requires at least 10 questions completed in previous level
      
      // Get level repository to access level data
      final levelRepo = ref.read(levelRepositoryProvider);
      await levelRepo.init();
      
      int currentMax = state.maxLevelUnlocked;
      bool changed = false;
      const requiredQuestions = 10;
      
      // Safety break to prevent infinite loops if cost is 0 or logic creates issues, though cost increases.
      for (int i = 0; i < 100; i++) {
           int nextLevelId = currentMax + 1;
           final nextLevel = levelRepo.getLevel(nextLevelId);
           if (nextLevel == null) break; // No more levels
           int cost = nextLevel.unlockCoins;
           
           // Check if user has enough coins
           if (state.totalCoins >= cost) {
               // Also check if previous level has at least 10 questions completed
               final previousLevelId = currentMax;
               final completed = state.completedQuestions[previousLevelId] ?? [];
               final completedCount = completed.length;
               
               if (completedCount >= requiredQuestions) {
                   currentMax = nextLevelId;
                   changed = true;
               } else {
                   // Don't unlock if previous level doesn't have 10 questions completed
                   break;
               }
           } else {
               break;
           }
      }
      
      if (changed) {
          state = state.copyWith(maxLevelUnlocked: currentMax);
          await _save();
      }
  }
  
  // Unlock next level when player has completed at least 10 questions in previous level
  // This ensures level N+1 only unlocks after playing 10 questions in level N AND having enough coins
  Future<void> unlockNextLevelOnCompletion(int completedLevelId, List<int> allQuestionIds) async {
      await _checkAndUnlockNextLevel(completedLevelId);
  }
  
  // Check if player has completed at least 10 questions in a level and unlock next level if conditions are met
  Future<void> _checkAndUnlockNextLevel(int levelId) async {
      // Check if at least 10 questions in the level are completed
      final completed = state.completedQuestions[levelId] ?? [];
      final completedCount = completed.length;
      const requiredQuestions = 10;
      
      if (completedCount >= requiredQuestions) {
          // Player has completed at least 10 questions, unlock next level if user has enough coins
          final nextLevelId = levelId + 1;
          
          // Get level repository to access level data
          final levelRepo = ref.read(levelRepositoryProvider);
          await levelRepo.init();
          final nextLevel = levelRepo.getLevel(nextLevelId);
          
          if (nextLevel != null) {
              final cost = nextLevel.unlockCoins;
              
              // Only unlock if:
              // 1. Next level is not already unlocked
              // 2. User has enough coins
              if (nextLevelId > state.maxLevelUnlocked && state.totalCoins >= cost) {
                  state = state.copyWith(maxLevelUnlocked: nextLevelId);
                  await _save();
              }
          }
      }
  }
  
  // Helper not to confuse addCoins parameter name
  int newCoinsEarned({required int amount}) => state.totalCoins + amount; // Just a helper
}

final userProgressProvider = NotifierProvider<UserProgressNotifier, UserProgress>(UserProgressNotifier.new);

final initUserProgressProvider = FutureProvider<void>((ref) async {
  await ref.read(userProgressProvider.notifier).init();
});
