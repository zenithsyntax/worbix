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
                left: position.dx - 50,
                top: position.dy - 50,
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
    final nodeSpacing = math.max(180.0, screenHeight / (levelCount + 1));
    final pathWidth = screenWidth * 0.7;
    final startX = screenWidth * 0.15;
    final topPadding = 150.0;

    for (int i = 0; i < levelCount; i++) {
      final progress = i / math.max(1, levelCount - 1);
      double x, y;

      // Create smooth S-curve path using easing functions for natural flow
      if (progress < 0.3) {
        // Top curve - smooth arc going down and right
        final localProgress = progress / 0.3;
        final eased = _easeInOutCubic(localProgress);
        x = startX + (pathWidth * 0.35 * eased);
        y = topPadding + (nodeSpacing * i * 0.9);
      } else if (progress < 0.6) {
        // Right side - smooth vertical descent with slight curve
        final localProgress = (progress - 0.3) / 0.3;
        final eased = _easeInOutCubic(localProgress);
        // Add slight horizontal curve for smoothness
        final curveOffset = math.sin(localProgress * math.pi) * 15;
        x =
            startX +
            pathWidth * 0.35 +
            (pathWidth * 0.25 * eased) +
            curveOffset;
        y =
            topPadding +
            (nodeSpacing * levelCount * 0.3 * 0.9) +
            (nodeSpacing * (i - levelCount * 0.3) * 1.1);
      } else if (progress < 0.8) {
        // Bottom curve - smooth transition to straight line
        final localProgress = (progress - 0.6) / 0.2;
        final eased = _easeInOutCubic(localProgress);
        // Smooth curve transitioning to left side
        x = startX + pathWidth * 0.6 - (pathWidth * 0.4 * (1 - eased));
        y =
            topPadding +
            (nodeSpacing * levelCount * 0.6) +
            (nodeSpacing * (i - levelCount * 0.6) * 0.8);
      } else {
        // End section - smooth straight line going down with small curve at the end
        final localProgress = (progress - 0.8) / 0.2;

        // Start position (where curve ends)
        final startXPos = startX + pathWidth * 0.2;
        final startYPos = topPadding + (nodeSpacing * levelCount * 0.8);

        // End position (straight down, slightly to the left with small curve)
        final endXPos = startX + pathWidth * 0.15;
        final endYPos =
            startYPos + (nodeSpacing * (i - levelCount * 0.8) * 1.2);

        // For most of the path (first 85%), make it perfectly straight
        if (localProgress < 0.85) {
          // Linear interpolation for straight line
          x = startXPos + (endXPos - startXPos) * (localProgress / 0.85);
          y = startYPos + (endYPos - startYPos) * (localProgress / 0.85);
        } else {
          // Last 15% - add a small gentle curve to the left
          final curveProgress = (localProgress - 0.85) / 0.15;
          final eased = _easeInOutCubic(curveProgress);

          // Base straight line position at 85%
          final straightX = startXPos + (endXPos - startXPos) * 0.85;
          final straightY = startYPos + (endYPos - startYPos) * 0.85;

          // Add small curve - slight leftward arc
          final curveAmount = math.sin(eased * math.pi) * 8; // Small curve
          x = straightX + (endXPos - straightX) * eased - curveAmount;
          y = straightY + (endYPos - straightY) * eased;
        }
      }

      positions.add(Offset(x, y));
    }

    return positions;
  }

  // Smooth easing function for natural curves
  double _easeInOutCubic(double t) {
    return t < 0.5 ? 4 * t * t * t : 1 - math.pow(-2 * t + 2, 3) / 2;
  }

  double _calculateTotalHeight(int levelCount, double screenHeight) {
    // Increased spacing to match node spacing
    final nodeSpacing = math.max(180.0, screenHeight / (levelCount + 1));
    return 150 + (nodeSpacing * levelCount * 1.3);
  }

  List<Widget> _buildDecorativeElements(
    double screenWidth,
    double totalHeight,
  ) {
    return [
      // Top right - Letter icon
      Positioned(right: 30, top: 60, child: _LetterIcon(letter: 'W', size: 40)),
      // Center - Crossword icon (in the U-turn area)
      Positioned(
        left: screenWidth * 0.5 - 20,
        top: totalHeight * 0.6,
        child: _CrosswordIcon(size: 35),
      ),
      // Top left - Letter icon
      Positioned(left: 30, top: 80, child: _LetterIcon(letter: 'A', size: 35)),
      // Right side - Letter icon
      Positioned(
        right: 25,
        top: totalHeight * 0.4,
        child: _LetterIcon(letter: 'B', size: 30),
      ),
      // Left side - Letter icon
      Positioned(
        left: 20,
        top: totalHeight * 0.75,
        child: _LetterIcon(letter: 'X', size: 32),
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
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Draw shadow path
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();

    if (nodePositions.length == 1) {
      // Single node - just draw a point
      path.addOval(Rect.fromCircle(center: nodePositions[0], radius: 10));
    } else {
      // Use smooth cubic Bezier curves for all segments
      path.moveTo(nodePositions[0].dx, nodePositions[0].dy);

      for (int i = 0; i < nodePositions.length - 1; i++) {
        final p0 = nodePositions[math.max(0, i - 1)];
        final p1 = nodePositions[i];
        final p2 = nodePositions[i + 1];
        final p3 = nodePositions[math.min(nodePositions.length - 1, i + 2)];

        // Check if this is in the last section (last 20% of nodes)
        final isLastSection = i >= nodePositions.length * 0.8;

        // For last section, use smaller tension for straighter lines
        final t = isLastSection ? 0.1 : 0.3; // Smaller tension = straighter

        // Calculate direction vectors
        final d1 = i == 0
            ? Offset(p2.dx - p1.dx, p2.dy - p1.dy)
            : Offset(p1.dx - p0.dx, p1.dy - p0.dy);

        final d2 = i == nodePositions.length - 2
            ? Offset(p2.dx - p1.dx, p2.dy - p1.dy)
            : Offset(p3.dx - p2.dx, p3.dy - p2.dy);

        // Normalize direction vectors
        final len1 = math.sqrt(d1.dx * d1.dx + d1.dy * d1.dy);
        final len2 = math.sqrt(d2.dx * d2.dx + d2.dy * d2.dy);

        final dir1 = len1 > 0
            ? Offset(d1.dx / len1, d1.dy / len1)
            : Offset(0.0, 1.0);
        final dir2 = len2 > 0
            ? Offset(d2.dx / len2, d2.dy / len2)
            : Offset(0.0, 1.0);

        // Calculate distance between points
        final dist = math.sqrt(
          (p2.dx - p1.dx) * (p2.dx - p1.dx) + (p2.dy - p1.dy) * (p2.dy - p1.dy),
        );

        // Control points for smooth cubic Bezier
        // For last section, make control points closer to create straighter lines
        final controlPoint1 = Offset(
          p1.dx + dir1.dx * dist * t,
          p1.dy + dir1.dy * dist * t,
        );

        final controlPoint2 = Offset(
          p2.dx - dir2.dx * dist * t,
          p2.dy - dir2.dy * dist * t,
        );

        // Draw smooth cubic Bezier curve
        path.cubicTo(
          controlPoint1.dx,
          controlPoint1.dy,
          controlPoint2.dx,
          controlPoint2.dy,
          p2.dx,
          p2.dy,
        );
      }
    }

    // Draw shadow first (offset slightly)
    final shadowPath = Path();
    shadowPath.addPath(path, const Offset(2, 2));
    canvas.drawPath(shadowPath, shadowPaint);

    // Draw main path
    canvas.drawPath(path, pathPaint);
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
        width: 100,
        height: 100,
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
              ? Icon(Icons.lock, color: Colors.white.withOpacity(0.7), size: 40)
              : Text(
                  "${level.id}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
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

  const _LetterIcon({required this.letter, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFFFB84D), width: 2),
      ),
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            fontSize: size * 0.5,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFFF8C00),
          ),
        ),
      ),
    ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack).fade();
  }
}

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
