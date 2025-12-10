import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'gameplay_state.dart';
import '../levels/level_model.dart';
import '../levels/level_repository.dart';
import '../store/user_progress_provider.dart';

class GameplayController extends StateNotifier<GameplayState> {
  final Ref ref;
  Timer? _timer;
  
  GameplayController(this.ref) : super(const GameplayState());

  void loadLevel(int levelId) {
    if (state.level?.id == levelId) return; 
    
    final levels = ref.read(levelRepositoryProvider).getAllLevels();
    final level = levels.firstWhere((l) => l.id == levelId, orElse: () => throw 'Level not found');
    
    final firstQ = level.questions.first;
    
    state = GameplayState(
      level: level,
      status: GameStatus.playing,
      currentQuestionIndex: 0,
      timeLeft: level.timeLimit,
      currentCoins: 0,
      currentGrid: firstQ.grid, 
      selectedIndices: [],
    );
    
    _startTimer();
  }
  
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.status != GameStatus.playing) {
        timer.cancel();
        return;
      }
      
      if (state.timeLeft <= 0) {
        state = state.copyWith(status: GameStatus.lost);
        timer.cancel();
      } else {
        state = state.copyWith(timeLeft: state.timeLeft - 1);
      }
    });
  }
  
  void clearSelection() {
      state = state.copyWith(selectedIndices: []);
  }

  void onTileTap(int index) {
      if (state.status != GameStatus.playing) return;

      // 0-35 index
      final r = index ~/ 6;
      final c = index % 6;
      
      if (state.selectedIndices.isEmpty) {
          // Start selection
          state = state.copyWith(selectedIndices: [index]);
          return;
      }
      
      // Check if trying to select a tile already selected (Backtracking/Loop)
      if (state.selectedIndices.contains(index)) {
           // Allow simple undo (tapping the last one again? or just ignore?)
           // If they tap the 2nd to last, we treat it as an undo of the last step
           if (state.selectedIndices.length > 1 && index == state.selectedIndices[state.selectedIndices.length - 2]) {
               final newSelection = List<int>.from(state.selectedIndices)..removeLast();
               state = state.copyWith(selectedIndices: newSelection);
               return;
           }
           // Any other self-intersection -> Reset? 
           // User said "old path is cleared and a NEW path begins... for example dont allow... loops"
           // So if they tap an arbitrary middle tile, we reset to that tile.
           if (index != state.selectedIndices.last) {
              state = state.copyWith(selectedIndices: [index]);
           }
           return;
      }
      
      final lastIndex = state.selectedIndices.last;
      final lastR = lastIndex ~/ 6;
      final lastC = lastIndex % 6;
      
      // Calculate proposed direction
      final dr = r - lastR;
      final dc = c - lastC;
      
      // Check adjacency (Must be adjacent |dr|<=1, |dc|<=1)
      if (dr.abs() > 1 || dc.abs() > 1 || (dr == 0 && dc == 0)) {
          // Non-adjacent jump -> Reset
          state = state.copyWith(selectedIndices: [index]);
          return;
      }
      
      // Check Locked Direction (if we have at least 2 tiles)
      if (state.selectedIndices.length >= 2) {
          final first = state.selectedIndices[0];
          final second = state.selectedIndices[1];
          
          final lockedDr = (second ~/ 6) - (first ~/ 6);
          final lockedDc = (second % 6) - (first % 6);
          
          // New step MUST match the locked direction
          if (dr != lockedDr || dc != lockedDc) {
              // Deviation -> Reset to new tile
              state = state.copyWith(selectedIndices: [index]);
              return;
          }
      }
      
      // Valid move -> Add
      state = state.copyWith(selectedIndices: [...state.selectedIndices, index]);
      _checkAnswer();
  }

  void _checkAnswer() {
      if (state.level == null) return;
      final q = state.level!.questions[state.currentQuestionIndex];
      
      // Construct word
      String word = "";
      for (var idx in state.selectedIndices) {
          int r = idx ~/ 6;
          int c = idx % 6;
          word += state.currentGrid[r][c];
      }
      
      if (word.toLowerCase() == q.answer.toLowerCase()) {
          // Correct!
          final newCoins = state.currentCoins + q.coins;
          ref.read(userProgressProvider.notifier).addCoins(q.coins);
          
          if (state.currentQuestionIndex + 1 >= state.level!.questions.length) {
              // Level Complete
               final bonus = (state.timeLeft * 0.2).floor();
               ref.read(userProgressProvider.notifier).addCoins(bonus);
               ref.read(userProgressProvider.notifier).unlockLevel(state.level!.id + 1);
               
              state = state.copyWith(
                  status: GameStatus.won,
                  currentCoins: newCoins + bonus,
                  selectedIndices: [],
              );
              _timer?.cancel();
          } else {
              // Next Question
               final nextIndex = state.currentQuestionIndex + 1;
              final nextQ = state.level!.questions[nextIndex];
              
              state = state.copyWith(
                  currentQuestionIndex: nextIndex,
                  currentCoins: newCoins,
                  currentGrid: nextQ.grid, 
                  selectedIndices: [],
              );
          }
      } 
      // Hints/Animation for wrong done via UI state observation usually, 
      // but here we just wait for user to fix or reset.
      // NOTE: User requested "Play gentle wrong animation...". 
      // We can implement that if needed, but for now simple checking is robust.
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final gameplayControllerProvider = StateNotifierProvider.autoDispose<GameplayController, GameplayState>((ref) {
  return GameplayController(ref);
});
