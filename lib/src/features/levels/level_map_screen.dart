import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'level_repository.dart'; // Same directory
import '../store/user_progress_provider.dart'; // Sibling feature
import '../gameplay/gameplay_screen.dart'; // Sibling feature

class LevelMapScreen extends ConsumerWidget {
  const LevelMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    print('Building LevelMapScreen');
    final levelsAsync = ref.watch(levelsProvider);
    final userProgress = ref.watch(userProgressProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Level"),
        actions: [
            Center(child: Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Text("\$ ${userProgress.coins}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ))
        ],
      ),
      body: levelsAsync.when(
        data: (levels) {
          print('Levels loaded: ${levels.length}');
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 1,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: levels.length,
            itemBuilder: (context, index) {
                final level = levels[index];
                print('Rendering level ${level.id}');
                final isLocked = level.id > userProgress.maxLevelUnlocked;
                
                return GestureDetector(
                    onTap: isLocked ? null : () {
                        Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => GameplayScreen(levelId: level.id))
                        );
                    },
                    child: Container(
                        decoration: BoxDecoration(
                            color: isLocked ? Colors.grey : Colors.orange,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                                BoxShadow(color: Colors.black.withAlpha(50), blurRadius: 4, offset: const Offset(2,2))
                            ]
                        ),
                        alignment: Alignment.center,
                        child: isLocked 
                            ? const Icon(Icons.lock, color: Colors.white) 
                            : Text("${level.id}", style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Error: $err")),
      ),
    );
  }
}
