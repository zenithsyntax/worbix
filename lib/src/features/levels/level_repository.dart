import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/logger.dart';
import 'level_model.dart';
import 'package:flutter/foundation.dart';

class LevelRepository {
  List<Level> _levels = [];
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    try {
      final String jsonString = await rootBundle.loadString('assets/levels.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      _levels = jsonList.map((json) => Level.fromJson(json)).toList();
      
      _validateLevels();
      
      _initialized = true;
    } catch (e) {
      debugPrint("Error loading levels: $e");
      rethrow;
    }
  }
  
  void _validateLevels() {
      for (var level in _levels) {
          if (level.gridSize != 36) debugPrint('Warning: Level ${level.id} grid size mismatch');
          
          for (var q in level.questions) {
              if (q.grid.length != 6 || q.grid.any((r) => r.length != 6)) {
                  debugPrint('Error: Level ${level.id} Q${q.qId} grid is not 6x6');
                  continue;
              }
              
              if (q.answer.length != q.answerPlacement.path.length) {
                  debugPrint('Error: Level ${level.id} Q${q.qId} answer length mismatch');
              }
              
              String gridWord = "";
              for (var point in q.answerPlacement.path) {
                  final r = point['row']!;
                  final c = point['col']!;
                  if (r < 0 || r > 5 || c < 0 || c > 5) {
                      debugPrint('Error: Level ${level.id} Q${q.qId} path out of bounds');
                      break;
                  }
                  gridWord += q.grid[r][c];
              }
              
              if (gridWord.toLowerCase() != q.answer.toLowerCase()) {
                  debugPrint('Error: Level ${level.id} Q${q.qId} grid mismatch. Found "$gridWord", expected "${q.answer}"');
              }
          }
      }
  }

  List<Level> getAllLevels() => _levels;
  
  Level? getLevel(int id) {
    try {
        return _levels.firstWhere((l) => l.id == id);
    } catch (_) {
        return null;
    }
  }
}

final levelRepositoryProvider = Provider<LevelRepository>((ref) {
  return LevelRepository();
});

final levelsProvider = FutureProvider<List<Level>>((ref) async {
  final repo = ref.watch(levelRepositoryProvider);
  await repo.init(); 
  return repo.getAllLevels();
});
