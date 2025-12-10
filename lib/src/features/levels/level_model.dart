import 'package:flutter/foundation.dart';

class AnswerPlacement {
  final List<Map<String, int>> path;

  const AnswerPlacement({
    required this.path,
  });

  factory AnswerPlacement.fromJson(Map<String, dynamic> json) {
    var rawPath = json['path'] as List;
    var pathList = rawPath.map((item) => Map<String, int>.from(item)).toList();
    return AnswerPlacement(path: pathList);
  }
}

class Question {
  final int qId;
  final int coins;
  final List<List<String>> grid; 
  final AnswerPlacement answerPlacement;
  final String question;
  final String answer;

  const Question({
    required this.qId,
    required this.coins,
    required this.grid,
    required this.answerPlacement,
    required this.question,
    required this.answer,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    var gridList = (json['grid'] as List).map((row) => List<String>.from(row)).toList();
    
    return Question(
      qId: json['q_id'] as int,
      coins: json['coins'] as int,
      grid: gridList,
      answerPlacement: AnswerPlacement.fromJson(json['answerPlacement']),
      question: json['question'] as String,
      answer: json['answer'] as String,
    );
  }

  bool get isValid {
      if (grid.length != 6) return false;
      for (var row in grid) {
          if (row.length != 6) return false;
      }
      return answer.isNotEmpty;
  }
}

class Level {
  final int id;
  final String title;
  final int timeLimit;
  final String orientation;
  final int gridSize;
  final List<Question> questions;

  const Level({
    required this.id,
    required this.title,
    required this.timeLimit,
    required this.orientation,
    required this.gridSize,
    required this.questions,
  });
  
  int get unlockCost => (id - 1) * 50;

  factory Level.fromJson(Map<String, dynamic> json) {
    return Level(
      id: json['id'] as int,
      title: json['title'] as String,
      timeLimit: json['timeLimit'] as int,
      orientation: json['orientation'] as String,
      gridSize: json['gridSize'] as int,
      questions: (json['questions'] as List)
          .map((e) => Question.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
