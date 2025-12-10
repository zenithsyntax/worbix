import 'package:flutter_test/flutter_test.dart';
import 'package:worbix/src/features/levels/level_model.dart';
import 'package:worbix/src/features/levels/level_repository.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LevelRepository Tests', () {
    test('Levels JSON should be valid and parsable', () async {
      final file = File('assets/levels.json');
      final jsonString = await file.readAsString();
      final List<dynamic> jsonList = json.decode(jsonString);
      
      final levels = jsonList.map((json) => Level.fromJson(json)).toList();
      
      expect(levels.isNotEmpty, true);
      expect(levels.length, 20); // We expect 20 levels
      
      for (var level in levels) {
        expect(level.questions.length, 10);
        expect(level.gridSize, 36);
        for (var q in level.questions) {
            expect(q.letters.length, 36);
            expect(q.answer.isNotEmpty, true);
        }
      }
    });

    test('Question model validation', () {
        final q = Question(
            qId: 1, 
            coins: 10, 
            letters: List.generate(36, (i) => 'a'), 
            question: 'test', 
            answer: 'aaa'
        );
        expect(q.isValid, true);
        
        final qInvalid = Question(
            qId: 1, 
            coins: 10, 
            letters: ['a'], 
            question: 'test', 
            answer: 'aaa'
        );
        expect(qInvalid.isValid, false);
    });
  });
}
