import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'gameplay_controller.dart';
import 'gameplay_state.dart';
import '../ads/ad_manager.dart';

class GameplayScreen extends ConsumerStatefulWidget {
  final int levelId;
  const GameplayScreen({super.key, required this.levelId});

  @override
  ConsumerState<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends ConsumerState<GameplayScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gameplayControllerProvider.notifier).loadLevel(widget.levelId);
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameplayControllerProvider);
    final controller = ref.read(gameplayControllerProvider.notifier);
    final theme = Theme.of(context);
    
    // Listen for Game Over / Win
    ref.listen(gameplayControllerProvider, (prev, next) {
        if (prev?.status != next.status) {
            if (next.status == GameStatus.won) {
                _confettiController.play();
                showDialog(context: context, barrierDismissible: false, builder: (_) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    backgroundColor: Colors.yellow.shade100,
                    title: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.orange, size: 40).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
                        const SizedBox(width: 8),
                        Text("Level Complete!", style: theme.textTheme.headlineSmall),
                      ],
                    ),
                    content: Text("You found the word!\nCoins: ${next.currentCoins}", style: theme.textTheme.bodyLarge),
                    actions: [
                        TextButton(
                            onPressed: () { 
                                Navigator.of(context).pop(); 
                                Navigator.of(context).pop(); 
                            },
                            child: const Text("Continue")
                        )
                    ],
                ).animate().scale(duration: 300.ms, curve: Curves.elasticOut));
            } else if (next.status == GameStatus.lost) {
                showDialog(context: context, barrierDismissible: false, builder: (_) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    title: const Text("Time's Up!"),
                    content: const Text("Try again?"),
                    actions: [
                        TextButton(
                            onPressed: () { 
                                Navigator.of(context).pop();
                                Navigator.of(context).pop();
                            },
                            child: const Text("Exit")
                        ),
                        TextButton(
                            onPressed: () {
                                Navigator.of(context).pop();
                                controller.loadLevel(widget.levelId);
                            },
                            child: const Text("Retry")
                        )
                    ],
                ));
            }
        }
    });

    if (state.status == GameStatus.loading) {
        return Scaffold(body: Center(child: CircularProgressIndicator(color: theme.colorScheme.primary)));
    }

    if (state.level == null) return const Scaffold();

    final q = state.level!.questions[state.currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text("Level ${state.level!.id}", style: theme.textTheme.headlineMedium?.copyWith(color: Colors.white)),
        actions: [
             Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                    child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), borderRadius: BorderRadius.circular(20)),
                        child: Row(
                            children: [
                                const Icon(Icons.monetization_on, color: Colors.yellowAccent),
                                const SizedBox(width: 4),
                                Text("${state.currentCoins}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18))
                            ],
                        )
                    )
                ),
             )
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
                // Clue Section
                Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]
                    ),
                    width: double.infinity,
                    child: Column(
                        children: [
                            Text("Question ${state.currentQuestionIndex + 1}/${state.level!.questions.length}", style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text(q.question, style: theme.textTheme.headlineSmall?.copyWith(fontSize: 22, color: theme.colorScheme.onSurface), textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            // Answer Blanks with Animation
                            Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(q.answer.length, (index) {
                                    String char = "";
                                    bool filled = false;
                                    if (index < state.selectedIndices.length) {
                                        int tapIdx = state.selectedIndices[index];
                                        int r = tapIdx ~/ 6;
                                        int c = tapIdx % 6;
                                        char = state.currentGrid[r][c];
                                        filled = true;
                                    }
                                    return Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 4),
                                        width: 40,
                                        height: 50,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                            border: Border(bottom: BorderSide(width: 3, color: filled ? theme.colorScheme.primary : Colors.grey.shade300))
                                        ),
                                        child: Text(char, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: theme.colorScheme.primary))
                                            .animate(target: filled ? 1 : 0).scale(duration: 200.ms, curve: Curves.easeOutBack),
                                    );
                                }),
                            )
                        ],
                    ),
                ),
                
                // Timer Bar
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: LinearProgressIndicator(
                        value: state.timeLeft / state.level!.timeLimit,
                        borderRadius: BorderRadius.circular(10),
                        minHeight: 12,
                        backgroundColor: Colors.grey.shade200,
                        color: state.timeLeft < 10 ? Colors.red : theme.colorScheme.tertiary,
                    ).animate(target: state.timeLeft < 10 ? 1 : 0).shake(hz: 2),
                ),
                
                Expanded(
                    child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final gridWidth = constraints.maxWidth;
                            final tileSize = (gridWidth - (5 * 8)) / 6; 
                            
                            return Stack(
                              children: [
                                GridView.builder(
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: 36,
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 6,
                                        crossAxisSpacing: 8,
                                        mainAxisSpacing: 8,
                                    ),
                                    itemBuilder: (context, index) {
                                        final r = index ~/ 6;
                                        final c = index % 6;
                                        final letter = state.currentGrid[r][c];
                                        final isSelected = state.selectedIndices.contains(index);
                                        
                                        return GestureDetector(
                                            onTap: () => controller.onTileTap(index),
                                            child: AnimatedContainer(
                                                duration: const Duration(milliseconds: 150),
                                                curve: Curves.easeOut,
                                                decoration: BoxDecoration(
                                                    color: isSelected ? theme.colorScheme.primary.withOpacity(0.2) : Colors.white,
                                                    borderRadius: BorderRadius.circular(12),
                                                    border: Border.all(
                                                        width: 2,
                                                        color: isSelected ? theme.colorScheme.primary : Colors.grey.shade200
                                                    ),
                                                    boxShadow: [
                                                        BoxShadow(
                                                            color: isSelected ? theme.colorScheme.primary.withOpacity(0.3) : Colors.black.withOpacity(0.05),
                                                            blurRadius: isSelected ? 8 : 4,
                                                            offset: const Offset(0, 4)
                                                        )
                                                    ]
                                                ),
                                                alignment: Alignment.center,
                                                child: Text(letter.toUpperCase(), style: TextStyle(
                                                    fontSize: 22, 
                                                    fontWeight: FontWeight.w900,
                                                    color: isSelected ? theme.colorScheme.primary : Colors.grey.shade700,
                                                )),
                                            ).animate().scale(delay: (30 * index).ms, duration: 400.ms, curve: Curves.easeOutBack),
                                        );
                                    },
                                ),
                                 IgnorePointer(
                                    child: CustomPaint(
                                      size: Size(constraints.maxWidth, constraints.maxHeight),
                                      painter: SelectionPathPainter(
                                         selectedIndices: state.selectedIndices,
                                         tileSize: tileSize,
                                         spacing: 8.0,
                                         color: theme.colorScheme.primary
                                      ),
                                    ),
                                 ),
                              ],
                            );
                          }
                        ),
                    )
                ),
                
                // Action Buttons
                Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                            ElevatedButton.icon(
                                onPressed: () => controller.clearSelection(),
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text("Reset"),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade300, foregroundColor: Colors.black87),
                            ),
                            ElevatedButton.icon(
                                onPressed: () {
                                    ref.read(adManagerProvider).showRewarded((reward) {
                                        final start = q.answerPlacement.path.first;
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hint: Answer starts at (R${start['row']}, C${start['col']})")));
                                    });
                                },
                                icon: const Icon(Icons.lightbulb_outline),
                                label: const Text("Hint"),
                                style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.secondary),
                            ),
                        ],
                    ),
                ),
                 if (ref.watch(adManagerProvider).bannerAd != null)
                     SizedBox(
                        height: 50,
                        child: AdWidget(ad: ref.watch(adManagerProvider).bannerAd!),
                     ),
            ],
          ),
          
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
            ),
          ),
        ],
      ),
    );
  }
}

class SelectionPathPainter extends CustomPainter {
  final List<int> selectedIndices;
  final double tileSize;
  final double spacing;
  final Color color;

  SelectionPathPainter({required this.selectedIndices, required this.tileSize, required this.spacing, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (selectedIndices.length < 2) return;

    final paint = Paint()
      ..color = color.withOpacity(0.5)
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    
    for (int i = 0; i < selectedIndices.length; i++) {
       final idx = selectedIndices[i];
       final r = idx ~/ 6;
       final c = idx % 6;
       
       final x = c * (tileSize + spacing) + tileSize / 2;
       final y = r * (tileSize + spacing) + tileSize / 2;
       
       if (i == 0) {
           path.moveTo(x, y);
       } else {
           path.lineTo(x, y);
       }
    }
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(SelectionPathPainter oldDelegate) {
     return oldDelegate.selectedIndices != selectedIndices;
  }
}
