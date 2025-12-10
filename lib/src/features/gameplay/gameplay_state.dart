import 'package:flutter/foundation.dart';
import '../levels/level_model.dart';

enum GameStatus { loading, playing, won, lost, paused }

class GameplayState {
  final Level? level;
  final GameStatus status;
  final int currentQuestionIndex;
  final int timeLeft;
  final int currentCoins;
  
  // Selection state
  final List<int> selectedIndices; // Flat indices 0-35
  final List<List<String>> currentGrid; // 6x6 

  const GameplayState({
    this.level,
    this.status = GameStatus.loading,
    this.currentQuestionIndex = 0,
    this.timeLeft = 0,
    this.currentCoins = 0,
    this.selectedIndices = const [],
    this.currentGrid = const [],
  });
  
  GameplayState copyWith({
    Level? level,
    GameStatus? status,
    int? currentQuestionIndex,
    int? timeLeft,
    int? currentCoins,
    List<int>? selectedIndices,
    List<List<String>>? currentGrid,
  }) {
    return GameplayState(
      level: level ?? this.level,
      status: status ?? this.status,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      timeLeft: timeLeft ?? this.timeLeft,
      currentCoins: currentCoins ?? this.currentCoins,
      selectedIndices: selectedIndices ?? this.selectedIndices,
      currentGrid: currentGrid ?? this.currentGrid,
    );
  }
}
