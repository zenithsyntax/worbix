import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../levels/level_repository.dart';
import '../store/user_progress_provider.dart';
import '../store/user_progress_model.dart';
import '../gameplay/gameplay_screen.dart';
import '../settings/settings_screen.dart';
import '../ads/ad_service.dart';
import '../ads/ad_manager.dart';
import '../levels/level_model.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final levelsAsync = ref.watch(levelsProvider);
    final userProgress = ref.watch(userProgressProvider);
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Worbix",
          style: theme.textTheme.displaySmall?.copyWith(
            color: Colors.white,
            fontSize: 32,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.monetization_on, color: Colors.yellowAccent),
                const SizedBox(width: 4),
                Text(
                  "${userProgress.totalCoins}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFF5E6D3), // Light beige
              const Color(0xFFE8D5C4), // Slightly darker beige
            ],
          ),
        ),
        child: levelsAsync.when(
          data: (levels) {
            return RoadmapView(
              levels: levels,
              userProgress: userProgress,
              onLevelTap: (level) async {
                final isLocked = level.id > userProgress.maxLevelUnlocked;
                final unlockCost = level.unlockCost;

                if (isLocked) {
                  _showLockedLevelDialog(
                    context,
                    ref,
                    level,
                    unlockCost,
                    userProgress.totalCoins,
                  );
                } else {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => GameplayScreen(levelId: level.id),
                    ),
                  );
                  adService.showInterstitialAd(onAdDismissed: () {});
                }
              },
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: Colors.orange),
          ),
          error: (err, st) => Center(
            child: Text(
              "Error loading levels",
              style: TextStyle(color: Colors.brown.shade900),
            ),
          ),
        ),
      ),
    );
  }

  void _showLockedLevelDialog(
    BuildContext context,
    WidgetRef ref,
    Level level,
    int unlockCost,
    int currentCoins,
  ) {
    // Preload rewarded ad when dialog opens
    ref.read(adManagerProvider).loadRewarded();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.lock, color: Colors.orange, size: 32),
            const SizedBox(width: 8),
            Text(
              "Level ${level.id} Locked",
              style: const TextStyle(fontSize: 20),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "You need $unlockCost coins to unlock this level.",
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.monetization_on, color: Colors.yellowAccent),
                const SizedBox(width: 4),
                Text(
                  "You have: $currentCoins coins",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text("Play Again"),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              // Get ScaffoldMessenger and Navigator before closing dialog
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);

              // Close dialog first
              navigator.pop();

              // Show loading message
              scaffoldMessenger.showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text("Loading ad..."),
                    ],
                  ),
                  duration: Duration(seconds: 5),
                ),
              );

              // Wait a moment for ad to potentially load
              await Future.delayed(const Duration(milliseconds: 500));

              // Show rewarded ad
              ref
                  .read(adManagerProvider)
                  .showRewarded(
                    (reward) {
                      // Reward earned - add 10 coins and unlock the level
                      ref.read(userProgressProvider.notifier).addCoins(10);
                      ref
                          .read(userProgressProvider.notifier)
                          .unlockLevel(level.id);
                      // Hide loading snackbar and show success
                      scaffoldMessenger.hideCurrentSnackBar();
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            "Level ${level.id} unlocked! +10 coins",
                          ),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    onAdDismissed: () {
                      // Ad was watched - add 10 coins and unlock the level
                      ref.read(userProgressProvider.notifier).addCoins(10);
                      ref
                          .read(userProgressProvider.notifier)
                          .unlockLevel(level.id);
                      // Hide loading snackbar and show success
                      scaffoldMessenger.hideCurrentSnackBar();
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            "Level ${level.id} unlocked! +10 coins",
                          ),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    onAdNotReady: () {
                      // Hide loading snackbar and show error with retry option
                      scaffoldMessenger.hideCurrentSnackBar();
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: const Text(
                            "Ad failed to load. Please check your internet connection and try again.",
                          ),
                          duration: const Duration(seconds: 4),
                          backgroundColor: Colors.orange,
                          action: SnackBarAction(
                            label: 'Retry',
                            textColor: Colors.white,
                            onPressed: () {
                              // Retry loading and showing the ad
                              ref.read(adManagerProvider).loadRewarded();
                              // Show the ad again after a short delay
                              Future.delayed(const Duration(seconds: 2), () {
                                ref
                                    .read(adManagerProvider)
                                    .showRewarded(
                                      (reward) {
                                        ref
                                            .read(userProgressProvider.notifier)
                                            .addCoins(10);
                                        ref
                                            .read(userProgressProvider.notifier)
                                            .unlockLevel(level.id);
                                        scaffoldMessenger.showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              "Level ${level.id} unlocked! +10 coins",
                                            ),
                                            backgroundColor: Colors.green,
                                            duration: const Duration(
                                              seconds: 2,
                                            ),
                                          ),
                                        );
                                      },
                                      onAdDismissed: () {
                                        ref
                                            .read(userProgressProvider.notifier)
                                            .addCoins(10);
                                        ref
                                            .read(userProgressProvider.notifier)
                                            .unlockLevel(level.id);
                                        scaffoldMessenger.showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              "Level ${level.id} unlocked! +10 coins",
                                            ),
                                            backgroundColor: Colors.green,
                                            duration: const Duration(
                                              seconds: 2,
                                            ),
                                          ),
                                        );
                                      },
                                      onAdNotReady: () {
                                        scaffoldMessenger.showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "Ad still not ready. Please try again later.",
                                            ),
                                            duration: Duration(seconds: 3),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      },
                                    );
                              });
                            },
                          ),
                        ),
                      );
                    },
                  );
            },
            icon: const Icon(Icons.play_circle_outline),
            label: const Text("Watch Rewarded Ad"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// Roadmap View Widget
class RoadmapView extends StatefulWidget {
  final List<Level> levels;
  final UserProgress userProgress;
  final Function(Level) onLevelTap;

  const RoadmapView({
    super.key,
    required this.levels,
    required this.userProgress,
    required this.onLevelTap,
  });

  @override
  State<RoadmapView> createState() => _RoadmapViewState();
}

class _RoadmapViewState extends State<RoadmapView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Calculate path positions for levels
    final nodePositions = _calculateNodePositions(
      widget.levels.length,
      screenWidth,
      screenHeight,
    );

    // Calculate total height needed
    final totalHeight = _calculateTotalHeight(
      widget.levels.length,
      screenHeight,
    );

    return SingleChildScrollView(
      controller: _scrollController,
      child: SizedBox(
        width: screenWidth,
        height: totalHeight,
        child: Stack(
          children: [
            // Background path
            CustomPaint(
              size: Size(screenWidth, totalHeight),
              painter: RoadmapPathPainter(
                nodeCount: widget.levels.length,
                nodePositions: nodePositions,
              ),
            ),

            // Decorative letter and crossword icons
            ..._buildDecorativeElements(screenWidth, totalHeight),

            // Level nodes
            ...widget.levels.asMap().entries.map((entry) {
              final index = entry.key;
              final level = entry.value;
              final position = nodePositions[index];
              final isLocked = level.id > widget.userProgress.maxLevelUnlocked;
              final hasEnoughCoins =
                  widget.userProgress.totalCoins >= level.unlockCost;

              return Positioned(
                left: position.dx - 55,
                top: position.dy - 55,
                child:
                    LevelNode(
                          level: level,
                          isLocked: isLocked,
                          hasEnoughCoins:
                              hasEnoughCoins &&
                              level.id ==
                                  widget.userProgress.maxLevelUnlocked + 1,
                          onTap: () => widget.onLevelTap(level),
                        )
                        .animate(delay: (100 * index).ms)
                        .scale(duration: 500.ms, curve: Curves.easeOutBack)
                        .fade(duration: 400.ms),
              );
            }),
          ],
        ),
      ),
    );
  }

  List<Offset> _calculateNodePositions(
    int levelCount,
    double screenWidth,
    double screenHeight,
  ) {
    final positions = <Offset>[];
    // Increased spacing between nodes
    final nodeSpacing = math.max(140.0, screenHeight / (levelCount + 1));
    final pathWidth = screenWidth * 0.65;
    final startX = screenWidth * 0.175;
    final topPadding = 120.0;

    for (int i = 0; i < levelCount; i++) {
      final progress = i / math.max(1, levelCount - 1);
      double x, y;

      // Create snake-like path with multiple curves and ultra-smooth turns
      // Base vertical position
      // Reduce spacing between first and second levels
      double baseY;
      if (i == 0) {
        baseY = topPadding;
      } else if (i == 1) {
        // Second level - much closer to first level (reduced spacing)
        baseY = topPadding + (nodeSpacing * 0.5);
      } else {
        // Normal spacing for remaining levels
        baseY =
            topPadding + (nodeSpacing * 0.5) + (nodeSpacing * (i - 1) * 1.1);
      }
      y = baseY;

      // Primary snake curve - large S-shaped movement (4 full cycles for smooth flow)
      // Using smoother wave with phase adjustment for natural flow
      final primaryPhase = progress * math.pi * 4;
      final primaryCurve = math.sin(primaryPhase) * pathWidth * 0.55;

      // Secondary wave for more snake-like undulation (6 cycles for fine detail)
      // Use smoother blending with cosine for phase offset
      final secondaryPhase = progress * math.pi * 6;
      final secondaryWave = math.sin(secondaryPhase) * pathWidth * 0.12;

      // Tertiary wave for subtle snake movement (8 cycles)
      // Reduced amplitude for smoother overall curve
      final tertiaryPhase = progress * math.pi * 8;
      final tertiaryWave = math.sin(tertiaryPhase) * pathWidth * 0.05;

      // Enhanced smooth edge transitions using smoother easing
      final edgeSmoothing = (math.sin(progress * math.pi) * 0.5 + 0.5);
      final smoothBlend = edgeSmoothing * edgeSmoothing; // Quadratic smoothing

      // Center position for the snake path
      final centerX = startX + (pathWidth * 0.5);

      // Combine all curves with improved blending for ultra-smooth snake-like path
      x =
          centerX +
          primaryCurve +
          (secondaryWave * smoothBlend) +
          (tertiaryWave * 0.8);

      // Add vertical undulation for more realistic snake movement
      // Vertical wave creates up/down movement like a snake slithering
      // Use smoother cosine wave with adjusted phase
      final verticalPhase = progress * math.pi * 3.5;
      final verticalWave = math.cos(verticalPhase) * nodeSpacing * 0.18;
      y += verticalWave;

      // Add slight vertical offset based on horizontal position for depth
      // Reduced amplitude for smoother effect
      final depthOffset = math.sin(primaryPhase) * nodeSpacing * 0.08;
      y += depthOffset * 0.6;

      positions.add(Offset(x, y));
    }

    return positions;
  }

  double _calculateTotalHeight(int levelCount, double screenHeight) {
    // Increased spacing to match node spacing with extra for vertical waves
    final nodeSpacing = math.max(140.0, screenHeight / (levelCount + 1));
    // Add extra height for vertical snake undulation
    return 120 + (nodeSpacing * levelCount * 1.3);
  }

  List<Widget> _buildDecorativeElements(
    double screenWidth,
    double totalHeight,
  ) {
    return [
      // Puzzle 1: WORD/CROSS - Top left corner (rotated)
      // Positioned(
      //   left: 10,
      //   top: 50,
      //   child: _CrosswordPuzzle(
      //     tileSize: 45.0,
      //     spacing: 2.0,
      //     angle: -0.3,
      //     horizontalWord: 'WORD',
      //     verticalWord: 'CROSS',
      //     horizontalStartCol: 0,
      //     verticalStartRow: 0,
      //     intersectionRow: 2,
      //     intersectionCol: 1,
      //   ),
      // ),
      // Puzzle 2: GAME/PLAY - Top right corner (rotated)
      // Positioned(
      //   right: 10,
      //   top: 60,
      //   child: _CrosswordPuzzle(
      //     tileSize: 42.0,
      //     spacing: 2.0,
      //     angle: 0.4,
      //     horizontalWord: 'GAME',
      //     verticalWord: 'PLAY',
      //     horizontalStartCol: 0,
      //     verticalStartRow: 0,
      //     intersectionRow: 1,
      //     intersectionCol: 1,
      //   ),
      // ),
      // Puzzle 3: FUN/QUIZ - Bottom left corner (rotated)
      // Positioned(
      //   left: 15,
      //   top: totalHeight - 250,
      //   child: _CrosswordPuzzle(
      //     tileSize: 48.0,
      //     spacing: 2.0,
      //     angle: 0.25,
      //     horizontalWord: 'FUN',
      //     verticalWord: 'QUIZ',
      //     horizontalStartCol: 0,
      //     verticalStartRow: 0,
      //     intersectionRow: 1,
      //     intersectionCol: 1,
      //   ),
      // ),
      // Puzzle 4: BRAIN/TEST - Bottom right corner (rotated)
      // Positioned(
      //   right: 15,
      //   top: totalHeight - 280,
      //   child: _CrosswordPuzzle(
      //     tileSize: 40.0,
      //     spacing: 2.0,
      //     angle: -0.35,
      //     horizontalWord: 'BRAIN',
      //     verticalWord: 'TEST',
      //     horizontalStartCol: 0,
      //     verticalStartRow: 0,
      //     intersectionRow: 2,
      //     intersectionCol: 2,
      //   ),
      // ),
      // Puzzle 5: WORD/PUZZLE - Left side middle (rotated)
      // Positioned(
      //   left: 5,
      //   top: totalHeight * 0.3,
      //   child: _CrosswordPuzzle(
      //     tileSize: 38.0,
      //     spacing: 2.0,
      //     angle: 0.5,
      //     horizontalWord: 'WORD',
      //     verticalWord: 'PUZZLE',
      //     horizontalStartCol: 0,
      //     verticalStartRow: 0,
      //     intersectionRow: 2,
      //     intersectionCol: 1,
      //   ),
      // ),
      // Puzzle 6: CROSS/GRID - Right side middle (rotated)
      // Positioned(
      //   right: 5,
      //   top: totalHeight * 0.35,
      //   child: _CrosswordPuzzle(
      //     tileSize: 44.0,
      //     spacing: 2.0,
      //     angle: -0.45,
      //     horizontalWord: 'CROSS',
      //     verticalWord: 'GRID',
      //     horizontalStartCol: 0,
      //     verticalStartRow: 0,
      //     intersectionRow: 1,
      //     intersectionCol: 2,
      //   ),
      // ),
      // Center - Crossword icon (in the U-turn area)
      Positioned(
        left: screenWidth * 0.5 - 20,
        top: totalHeight * 0.6,
        child: _CrosswordIcon(size: 35),
      ),
      // Bottom area - Crossword icon
      Positioned(
        left: screenWidth * 0.3,
        top: totalHeight * 0.5,
        child: _CrosswordIcon(size: 28),
      ),
    ];
  }
}

// Roadmap Path Painter
class RoadmapPathPainter extends CustomPainter {
  final int nodeCount;
  final List<Offset> nodePositions;

  RoadmapPathPainter({required this.nodeCount, required this.nodePositions});

  @override
  void paint(Canvas canvas, Size size) {
    if (nodePositions.isEmpty) return;

    final pathPaint = Paint()
      ..color =
          const Color(0xFFFFB84D) // Orange-yellow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 26
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Draw shadow path
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 26
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();

    if (nodePositions.length == 1) {
      // Single node - just draw a point
      path.addOval(Rect.fromCircle(center: nodePositions[0], radius: 10));
    } else {
      // Use Catmull-Rom spline for ultra-smooth curves
      path.moveTo(nodePositions[0].dx, nodePositions[0].dy);

      // Generate ultra-smooth curve using enhanced Catmull-Rom spline with subdivision
      for (int i = 0; i < nodePositions.length - 1; i++) {
        final p0 = nodePositions[math.max(0, i - 1)];
        final p1 = nodePositions[i];
        final p2 = nodePositions[i + 1];
        final p3 = nodePositions[math.min(nodePositions.length - 1, i + 2)];

        // Check if this is in the last section (last 20% of nodes)
        final isLastSection = i >= nodePositions.length * 0.8;

        // Use even lower tension for maximum smoothness
        final baseTension = isLastSection ? 0.12 : 0.2; // Ultra-smooth tension

        // Calculate distances for centripetal parameterization
        final dist01 = math.sqrt(
          (p1.dx - p0.dx) * (p1.dx - p0.dx) + (p1.dy - p0.dy) * (p1.dy - p0.dy),
        );
        final dist12 = math.sqrt(
          (p2.dx - p1.dx) * (p2.dx - p1.dx) + (p2.dy - p1.dy) * (p2.dy - p1.dy),
        );
        final dist23 = math.sqrt(
          (p3.dx - p2.dx) * (p3.dx - p2.dx) + (p3.dy - p2.dy) * (p3.dy - p2.dy),
        );

        // Enhanced centripetal parameterization for maximum smoothness
        final alpha = 0.5;
        final t01 = dist01 < 0.001 ? 0.0 : math.pow(dist01, alpha);
        final t12 = dist12 < 0.001 ? 1.0 : math.pow(dist12, alpha);
        final t23 = dist23 < 0.001 ? 0.0 : math.pow(dist23, alpha);

        // Calculate refined control points using improved Catmull-Rom to Bezier conversion
        final total1 = t01 + t12;
        final total2 = t12 + t23;

        final t1 = total1 < 0.001 ? baseTension : baseTension * (t12 / total1);
        final t2 = total2 < 0.001 ? baseTension : baseTension * (t12 / total2);

        // Calculate ultra-smooth control points with refined calculations
        final cp1 = Offset(
          p1.dx + (p2.dx - p0.dx) * t1,
          p1.dy + (p2.dy - p0.dy) * t1,
        );

        final cp2 = Offset(
          p2.dx - (p3.dx - p1.dx) * t2,
          p2.dy - (p3.dy - p1.dy) * t2,
        );

        // Subdivide the curve into multiple segments for ultra-smooth rendering
        // This creates more intermediate points for smoother curves
        final segments = isLastSection
            ? 10
            : 16; // More segments = smoother curve

        for (int j = 0; j < segments; j++) {
          final t = j / segments;
          final nextT = (j + 1) / segments;

          // Calculate points on the Bezier curve
          final point1 = _evaluateBezier(p1, cp1, cp2, p2, t);
          final point2 = _evaluateBezier(p1, cp1, cp2, p2, nextT);

          if (j == 0) {
            if (i == 0) {
              path.moveTo(point1.dx, point1.dy);
            } else {
              path.lineTo(point1.dx, point1.dy);
            }
          }
          path.lineTo(point2.dx, point2.dy);
        }
      }
    }

    // Draw shadow first (offset slightly)
    final shadowPath = Path();
    shadowPath.addPath(path, const Offset(2, 2));
    canvas.drawPath(shadowPath, shadowPaint);

    // Draw main path
    canvas.drawPath(path, pathPaint);
  }

  // Evaluate a point on a cubic Bezier curve at parameter t (0 to 1)
  Offset _evaluateBezier(Offset p0, Offset p1, Offset p2, Offset p3, double t) {
    final u = 1.0 - t;
    final tt = t * t;
    final uu = u * u;
    final uuu = uu * u;
    final ttt = tt * t;

    final x =
        uuu * p0.dx + 3 * uu * t * p1.dx + 3 * u * tt * p2.dx + ttt * p3.dx;
    final y =
        uuu * p0.dy + 3 * uu * t * p1.dy + 3 * u * tt * p2.dy + ttt * p3.dy;

    return Offset(x, y);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Level Node Widget with 3D effects
class LevelNode extends StatelessWidget {
  final Level level;
  final bool isLocked;
  final bool hasEnoughCoins;
  final VoidCallback onTap;

  const LevelNode({
    super.key,
    required this.level,
    required this.isLocked,
    required this.hasEnoughCoins,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: isLocked
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.grey.shade600, Colors.grey.shade800],
                )
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFFFD700), // Gold
                    const Color(0xFFFFA500), // Orange-gold
                    const Color(0xFFFF8C00), // Darker orange
                  ],
                ),
          boxShadow: [
            BoxShadow(
              color: isLocked
                  ? Colors.black.withOpacity(0.3)
                  : Colors.orange.withOpacity(0.6),
              blurRadius: 15,
              offset: const Offset(0, 8),
              spreadRadius: 2,
            ),
            BoxShadow(
              color: isLocked
                  ? Colors.black.withOpacity(0.2)
                  : Colors.amber.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.white.withOpacity(0.9), width: 3),
        ),
        child: Center(
          child: isLocked
              ? Icon(Icons.lock, color: Colors.white.withOpacity(0.7), size: 44)
              : Text(
                  "${level.id}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 44,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        offset: Offset(1, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

// Letter Icon Widget
class _LetterIcon extends StatelessWidget {
  final String letter;
  final double size;
  final double angle;
  final Color color;
  final String? fontFamily;
  final Color tileColor;
  final bool hasShadow;

  const _LetterIcon({
    required this.letter,
    required this.size,
    this.angle = 0.0,
    required this.color,
    this.fontFamily,
    this.tileColor = Colors.white,
    this.hasShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: tileColor,
          borderRadius: BorderRadius.circular(4),
          boxShadow: hasShadow
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            letter,
            style: TextStyle(
              fontSize: size * 0.5,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 0.5,
              fontFamily: fontFamily,
            ),
          ),
        ),
      ),
    ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack).fade();
  }
}

// Crossword Puzzle Widget
// class _CrosswordPuzzle extends StatelessWidget {
//   final double tileSize;
//   final double spacing;
//   final double angle;
//   final String horizontalWord;
//   final String verticalWord;
//   final int horizontalStartCol;
//   final int verticalStartRow;
//   final int intersectionRow;
//   final int intersectionCol;

//   const _CrosswordPuzzle({
//     this.tileSize = 50.0,
//     this.spacing = 2.0,
//     this.angle = 0.0,
//     required this.horizontalWord,
//     required this.verticalWord,
//     required this.horizontalStartCol,
//     required this.verticalStartRow,
//     required this.intersectionRow,
//     required this.intersectionCol,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final tileWithSpacing = tileSize + spacing;

//     // Calculate grid dimensions
//     final maxCol = math.max(
//       horizontalStartCol + horizontalWord.length - 1,
//       intersectionCol,
//     );
//     final maxRow = math.max(
//       verticalStartRow + verticalWord.length - 1,
//       intersectionRow,
//     );

//     final width = (maxCol + 1) * tileWithSpacing;
//     final height = (maxRow + 1) * tileWithSpacing;

//     // Build tiles
//     final tiles = <Widget>[];

//     // Add horizontal word tiles (dark)
//     for (int i = 0; i < horizontalWord.length; i++) {
//       final col = horizontalStartCol + i;
//       final row = intersectionRow;
//       final letter = horizontalWord[i];

//       tiles.add(
//         Positioned(
//           left: col * tileWithSpacing,
//           top: row * tileWithSpacing,
//           child: _LetterIcon(
//             letter: letter,
//             size: tileSize,
//             angle: 0.0,
//             color: Colors.white,
//             tileColor: Colors.grey.shade800,
//             hasShadow: true,
//             fontFamily: null,
//           ),
//         ),
//       );
//     }

//     // Add vertical word tiles (white, skip intersection)
//     for (int i = 0; i < verticalWord.length; i++) {
//       final row = verticalStartRow + i;
//       final col = intersectionCol;
//       final letter = verticalWord[i];
//       final isIntersection = (col == intersectionCol && row == intersectionRow);

//       if (!isIntersection) {
//         tiles.add(
//           Positioned(
//             left: col * tileWithSpacing,
//             top: row * tileWithSpacing,
//             child: _LetterIcon(
//               letter: letter,
//               size: tileSize,
//               angle: 0.0,
//               color: Colors.white,
//               tileColor: Colors.white,
//               hasShadow: true,
//               fontFamily: null,
//             ),
//           ),
//         );
//       }
//     }

//     return Transform.rotate(
//       angle: angle,
//       child: Container(
//         width: width,
//         height: height,
//         child: Stack(children: tiles),
//       ),
//     );
//   }
// }

// Crossword Icon Widget
class _CrosswordIcon extends StatelessWidget {
  final double size;

  const _CrosswordIcon({required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _CrosswordPainter(),
    ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack).fade();
  }
}

class _CrosswordPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = size.width / 3;
    final strokeWidth = 2.0;

    // Draw crossword grid pattern
    final gridPaint = Paint()
      ..color = const Color(0xFFFFB84D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFFFF8C00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 1.5;

    // Draw filled cells in crossword pattern
    // Top row: left and right
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, cellSize, cellSize),
        const Radius.circular(2),
      ),
      fillPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, cellSize, cellSize),
        const Radius.circular(2),
      ),
      borderPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cellSize * 2, 0, cellSize, cellSize),
        const Radius.circular(2),
      ),
      fillPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cellSize * 2, 0, cellSize, cellSize),
        const Radius.circular(2),
      ),
      borderPaint,
    );

    // Middle row: all three
    for (int i = 0; i < 3; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cellSize * i, cellSize, cellSize, cellSize),
          const Radius.circular(2),
        ),
        fillPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cellSize * i, cellSize, cellSize, cellSize),
          const Radius.circular(2),
        ),
        borderPaint,
      );
    }

    // Bottom row: left and right
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, cellSize * 2, cellSize, cellSize),
        const Radius.circular(2),
      ),
      fillPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, cellSize * 2, cellSize, cellSize),
        const Radius.circular(2),
      ),
      borderPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cellSize * 2, cellSize * 2, cellSize, cellSize),
        const Radius.circular(2),
      ),
      fillPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cellSize * 2, cellSize * 2, cellSize, cellSize),
        const Radius.circular(2),
      ),
      borderPaint,
    );

    // Draw grid lines
    for (int i = 0; i <= 3; i++) {
      // Vertical lines
      canvas.drawLine(
        Offset(cellSize * i, 0),
        Offset(cellSize * i, size.height),
        gridPaint,
      );
      // Horizontal lines
      canvas.drawLine(
        Offset(0, cellSize * i),
        Offset(size.width, cellSize * i),
        gridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
