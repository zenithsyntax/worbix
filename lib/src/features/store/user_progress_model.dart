import 'dart:convert';

class UserProgress {
  final int totalCoins;
  final int maxLevelUnlocked;
  final int lastPlayedLevelId;
  final int lastPlayedQuestionIndex;
  final bool instructionsSeen;
  final bool soundEnabled;

  // Map<LevelID, List<QuestionID>>
  final Map<int, List<int>> completedQuestions;

  const UserProgress({
    this.totalCoins = 0,
    this.maxLevelUnlocked = 1,
    this.lastPlayedLevelId = 1,
    this.lastPlayedQuestionIndex = 0,
    this.instructionsSeen = false,
    this.soundEnabled = true,
    this.completedQuestions = const {},
  });

  UserProgress copyWith({
    int? totalCoins,
    int? maxLevelUnlocked,
    int? lastPlayedLevelId,
    int? lastPlayedQuestionIndex,
    bool? instructionsSeen,
    bool? soundEnabled,
    Map<int, List<int>>? completedQuestions,
  }) {
    return UserProgress(
      totalCoins: totalCoins ?? this.totalCoins,
      maxLevelUnlocked: maxLevelUnlocked ?? this.maxLevelUnlocked,
      lastPlayedLevelId: lastPlayedLevelId ?? this.lastPlayedLevelId,
      lastPlayedQuestionIndex:
          lastPlayedQuestionIndex ?? this.lastPlayedQuestionIndex,
      instructionsSeen: instructionsSeen ?? this.instructionsSeen,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      completedQuestions: completedQuestions ?? this.completedQuestions,
    );
  }

  // Hive/JSON serialization helpers if needed,
  // though for simple usage we might just store individual fields or a JSON string.
  // Given we are using Hive, we could register an adapter, or just store a Map.
  // For simplicity without code-gen for now, let's use toMap/fromMap if we store as JSON/Map in Hive,
  // or just use individual keys for top-level items.
  // But a single object is cleaner. Let's assume we store as a Map or JSON.

  Map<String, dynamic> toJson() {
    return {
      'totalCoins': totalCoins,
      'maxLevelUnlocked': maxLevelUnlocked,
      'lastPlayedLevelId': lastPlayedLevelId,
      'lastPlayedQuestionIndex': lastPlayedQuestionIndex,
      'instructionsSeen': instructionsSeen,
      'soundEnabled': soundEnabled,
      'completedQuestions': completedQuestions.map(
        (k, v) => MapEntry(k.toString(), v),
      ),
    };
  }

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    // completedQuestions handling
    final rawCompleted =
        json['completedQuestions'] as Map<String, dynamic>? ?? {};
    final Map<int, List<int>> parsedCompleted = {};
    rawCompleted.forEach((key, value) {
      final k = int.tryParse(key);
      if (k != null) {
        parsedCompleted[k] = List<int>.from(value as List);
      }
    });

    return UserProgress(
      totalCoins: json['totalCoins'] as int? ?? 0,
      maxLevelUnlocked: json['maxLevelUnlocked'] as int? ?? 1,
      lastPlayedLevelId: json['lastPlayedLevelId'] as int? ?? 1,
      lastPlayedQuestionIndex: json['lastPlayedQuestionIndex'] as int? ?? 0,
      instructionsSeen: json['instructionsSeen'] as bool? ?? false,
      soundEnabled: json['soundEnabled'] as bool? ?? true,
      completedQuestions: parsedCompleted,
    );
  }
}
