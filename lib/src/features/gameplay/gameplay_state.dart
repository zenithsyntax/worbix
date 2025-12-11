import '../levels/level_model.dart';

enum GameStatus { loading, playing, questionCompleted, won, lost, paused }

class GameplayState {
  final Level? level;
  final GameStatus status;
  final int currentQuestionIndex;
  final int timeLeft;
  final int currentCoins;
  
  // Selection state
  final List<int> selectedIndices; // Flat indices 0-35
  final Map<int, int> hintPositions; // Map of word position -> grid index for hints
  final List<List<String>> currentGrid; // 6x6 

  final int currentQuestionDuration; // Seconds spent on current question
  final int coinsEarnedLastQuestion;
  final bool isTimeExpired; // Track if time has run out for current question

  const GameplayState({
    this.level,
    this.status = GameStatus.loading,
    this.currentQuestionIndex = 0,
    this.timeLeft = 0,
    this.currentCoins = 0,
    this.selectedIndices = const [],
    this.hintPositions = const {},
    this.currentGrid = const [],
    this.currentQuestionDuration = 0,
    this.coinsEarnedLastQuestion = 0,
    this.isTimeExpired = false,
  });
  
  GameplayState copyWith({
    Level? level,
    GameStatus? status,
    int? currentQuestionIndex,
    int? timeLeft,
    int? currentCoins,
    List<int>? selectedIndices,
    Map<int, int>? hintPositions,
    List<List<String>>? currentGrid,
    int? currentQuestionDuration,
    int? coinsEarnedLastQuestion,
    bool? isTimeExpired,
  }) {
    return GameplayState(
      level: level ?? this.level,
      status: status ?? this.status,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      timeLeft: timeLeft ?? this.timeLeft,
      currentCoins: currentCoins ?? this.currentCoins,
      selectedIndices: selectedIndices ?? this.selectedIndices,
      hintPositions: hintPositions ?? this.hintPositions,
      currentGrid: currentGrid ?? this.currentGrid,
      currentQuestionDuration: currentQuestionDuration ?? this.currentQuestionDuration,
      coinsEarnedLastQuestion: coinsEarnedLastQuestion ?? this.coinsEarnedLastQuestion,
      isTimeExpired: isTimeExpired ?? this.isTimeExpired,
    );
  }
}
