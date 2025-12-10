import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'gameplay_state.dart';
import '../levels/level_repository.dart';
import '../store/user_progress_provider.dart';

class GameplayController extends StateNotifier<GameplayState> {
  final Ref ref;
  Timer? _timer;
  
  GameplayController(this.ref) : super(const GameplayState());

  Future<void> loadLevel(int levelId) async {
    // Determine where to start
    final levels = ref.read(levelRepositoryProvider).getAllLevels();
    final level = levels.firstWhere((l) => l.id == levelId, orElse: () => throw 'Level not found');
    
    // Check saved progress
    final userProgress = ref.read(userProgressProvider);
    int startIndex = 0;
    
    // If resuming the level we were last on, resume from specific question
    if (userProgress.lastPlayedLevelId == levelId) {
        startIndex = userProgress.lastPlayedQuestionIndex;
        
        // Ensure we don't start on a question we already finished
        // (Handles case where user quit after winning but before clicking Next)
        final completed = userProgress.completedQuestions[levelId] ?? [];
        while (startIndex < level.questions.length && completed.contains(level.questions[startIndex].qId)) {
            startIndex++;
        }
        
        if (startIndex >= level.questions.length) {
            // Level is fully complete or we are at the end?
            // If all questions are done, maybe we shouldn't reset to 0, but show "Level Complete" or just replay 0?
            // User requested "Resume progress...". If level is done, maybe just let them replay?
            // Or if unlocked next level, maybe we should have redirected them?
            // Let's reset to 0 for replay purposes if they manually selected this level again.
            // But if they just opened the app, we want them to go to the NEW level.
            // However, loadLevel is called with a specific ID.
            startIndex = 0; 
        }
    }
    
    final currentQ = level.questions[startIndex];
    
    state = GameplayState(
      level: level,
      status: GameStatus.playing,
      currentQuestionIndex: startIndex,
      timeLeft: level.timeLimit, // Each question starts with full time limit
      currentCoins: 0, // This is session coins? Or total? "Total coins earned (from all its questions)".
                       // Let's assume this tracks coins earned IN THIS SESSION for the level.
      currentGrid: currentQ.grid, 
      selectedIndices: [],
      currentQuestionDuration: 0,
      coinsEarnedLastQuestion: 0,
      isTimeExpired: false,
    );
    
    // Update saved position
    ref.read(userProgressProvider.notifier).savePosition(levelId, startIndex);
    
    _startTimer();
  }
  
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.status != GameStatus.playing) {
        // Don't cancel here if we just pause? 
        // Only cancel if game over/won. 
        // If question completed, we pause timer? -> Yes status changed to questionCompleted.
        return;
      }
      
      // Update duration (time spent on current question)
      state = state.copyWith(currentQuestionDuration: state.currentQuestionDuration + 1);
      
      // Countdown timer for current question
      if (state.timeLeft > 0) {
          final newTimeLeft = state.timeLeft - 1;
          state = state.copyWith(timeLeft: newTimeLeft);
          
          // Check if time ran out
          if (newTimeLeft == 0) {
              // Time's up - mark as expired but allow gameplay to continue
              state = state.copyWith(isTimeExpired: true);
              // Don't cancel timer or change status - let user continue playing
          }
      }
    });
  }
  
  void clearSelection() {
      state = state.copyWith(selectedIndices: []);
  }

  void selectFirstLetter(int row, int col) {
      if (state.status != GameStatus.playing) return;
      // Convert row/col to flat index (0-35)
      final index = row * 6 + col;
      state = state.copyWith(selectedIndices: [index]);
  }
  
  // Allow tile tapping even after time expires
  bool get _canPlay => state.status == GameStatus.playing;

  void onTileTap(int index) {
      if (!_canPlay) return;

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

  Future<void> _checkAnswer() async {
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
          
          // If time expired, only give 1 coin, otherwise calculate normally
          final int coinsEarned;
          if (state.isTimeExpired) {
              // Time expired - only reward 1 coin
              coinsEarned = 1;
          } else {
              // Calculate Coins based on remaining time (timer)
              // More time left = more coins, less time left = fewer coins
              // Formula: coinsEarned = maxCoins * (timeLeft / timeLimit)
              // Ensure minimum of 1 coin
              final maxCoins = q.coins;
              final timeLimit = state.level!.timeLimit;
              final timeLeft = state.timeLeft;
              
              // Calculate coins based on percentage of time remaining
              // If timeLeft is 140 and timeLimit is 140, you get 100% of coins
              // If timeLeft is 70 and timeLimit is 140, you get 50% of coins
              coinsEarned = (maxCoins * (timeLeft / timeLimit)).clamp(1.0, maxCoins.toDouble()).toInt();
          }
          
          // Save Progress (replay can earn coins again as per requirements)
          await ref.read(userProgressProvider.notifier).markQuestionCompleted(
              levelId: state.level!.id, 
              questionId: q.qId,
              coinsEarned: coinsEarned,
              allowReplayCoins: true, // Allow earning coins on replay
          );
          
          // Save position to next question if it exists (for proper resume)
          if (state.currentQuestionIndex + 1 < state.level!.questions.length) {
              await ref.read(userProgressProvider.notifier).savePosition(
                  state.level!.id, 
                  state.currentQuestionIndex + 1
              );
          }
          
          state = state.copyWith(
              status: GameStatus.questionCompleted,
              currentCoins: state.currentCoins + coinsEarned,
              coinsEarnedLastQuestion: coinsEarned,
              isTimeExpired: false, // Reset for next question
          );
          // Timer naturally effectively pauses because status != playing
      } 
  }

  void nextQuestion() {
      if (state.level == null) return;
      
      if (state.currentQuestionIndex + 1 >= state.level!.questions.length) {
          // Level Complete
           // Ensure unlock check runs one more time after level completion
           ref.read(userProgressProvider.notifier).checkAutoUnlock();
           
           state = state.copyWith(
               status: GameStatus.won,
               selectedIndices: [],
           );
           _timer?.cancel();
      } else {
          // Next Question
           final nextIndex = state.currentQuestionIndex + 1;
           final nextQ = state.level!.questions[nextIndex];
           
           // Update saved position
           ref.read(userProgressProvider.notifier).savePosition(state.level!.id, nextIndex);
           
           // Reset timer to full time limit for the new question
           state = state.copyWith(
               status: GameStatus.playing,
               currentQuestionIndex: nextIndex,
               timeLeft: state.level!.timeLimit, // Reset timer to level's time limit
               currentGrid: nextQ.grid, 
               selectedIndices: [],
               currentQuestionDuration: 0, // Reset duration counter
               coinsEarnedLastQuestion: 0,
               isTimeExpired: false, // Reset time expired flag
           );
           // Restart timer for the new question
           _startTimer();
      }
  }
  
  void jumpToQuestion(int index) {
      if (state.level == null || index < 0 || index >= state.level!.questions.length) return;
      
      final q = state.level!.questions[index];
      // Reset timer to full time limit when jumping to a question
      state = state.copyWith(
          status: GameStatus.playing,
          currentQuestionIndex: index,
          timeLeft: state.level!.timeLimit, // Reset timer to level's time limit
          currentGrid: q.grid,
          selectedIndices: [],
          currentQuestionDuration: 0, // Reset duration counter
          coinsEarnedLastQuestion: 0,
          isTimeExpired: false, // Reset time expired flag
      );
      // Restart timer for the question
      _startTimer();
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
