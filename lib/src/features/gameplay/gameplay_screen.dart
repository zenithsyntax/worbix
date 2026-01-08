import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'package:google_fonts/google_fonts.dart';
import 'gameplay_controller.dart';
import 'gameplay_state.dart';
import '../ads/ad_manager.dart';
import '../ads/ad_service.dart';
import '../store/user_progress_provider.dart';
import '../levels/level_repository.dart';
import '../levels/level_model.dart';
import 'widgets/question_completion_dialog.dart';
import 'widgets/instructions_dialog.dart';

class GameplayScreen extends ConsumerStatefulWidget {
  final int levelId;
  const GameplayScreen({super.key, required this.levelId});

  @override
  ConsumerState<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends ConsumerState<GameplayScreen> {
  late ConfettiController _confettiController;
  OverlayEntry? _floatingSnackBarOverlay;
  bool _isHintAdLoading = false;

  void _showFloatingSnackBar(
    String message, {
    Color? backgroundColor,
    IconData? icon,
    Duration duration = const Duration(seconds: 2),
  }) {
    // Remove existing overlay if present
    _hideFloatingSnackBar();

    final overlay = Overlay.of(context);
    final screenSize = MediaQuery.of(context).size;

    _floatingSnackBarOverlay = OverlayEntry(
      builder: (context) => Positioned(
        top: 60,
        left: screenSize.width * 0.05,
        right: screenSize.width * 0.05,
        child: Material(
          color: Colors.transparent,
          elevation: 0,
          child:
              Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: backgroundColor ?? const Color(0xFF323232),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                          spreadRadius: 0,
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (icon != null) ...[
                          Icon(
                            icon,
                            color: Colors.white.withOpacity(0.9),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                        ],
                        Flexible(
                          child: Text(
                            message,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                              letterSpacing: 0.2,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  )
                  .animate()
                  .slideY(
                    begin: -0.5,
                    end: 0,
                    duration: 300.ms,
                    curve: Curves.easeOutCubic,
                  )
                  .fadeIn(duration: 250.ms, curve: Curves.easeOut),
        ),
      ),
    );

    overlay.insert(_floatingSnackBarOverlay!);

    // Auto-remove after duration
    Future.delayed(duration, () {
      _hideFloatingSnackBar();
    });
  }

  void _hideFloatingSnackBar() {
    if (_floatingSnackBarOverlay != null) {
      _floatingSnackBarOverlay!.remove();
      _floatingSnackBarOverlay = null;
    }
  }

  String _getLockedMessage({
    required bool hasEnoughCoins,
    required bool hasEnoughQuestions,
    required int cost,
    required int totalCoins,
    required int completedCount,
  }) {
    if (hasEnoughCoins && !hasEnoughQuestions) {
      return "Complete 10 questions in this level.\nYou have $completedCount/10.";
    } else if (!hasEnoughCoins && hasEnoughQuestions) {
      return "Need $cost coins.\nYou have $totalCoins.";
    } else if (!hasEnoughCoins && !hasEnoughQuestions) {
      return "Need $cost coins (you have $totalCoins)\nand 10 questions completed\n(you have $completedCount/10).";
    } else {
      // Should be unlocked, but show coins info anyway
      return "Need $cost coins.\nYou have $totalCoins.";
    }
  }

  Future<void> _handleLevelWon(
    BuildContext context,
    WidgetRef ref,
    GameplayState state,
    int levelId,
    ThemeData theme,
  ) async {
    // Wait a moment for unlock check to complete, then check status
    await Future.delayed(const Duration(milliseconds: 500));
    // Re-read progress to get updated unlock status
    final progress = ref.read(userProgressProvider);
    final nextId = levelId + 1;

    // Get the actual next level to check unlock cost
    final levelRepo = ref.read(levelRepositoryProvider);
    await levelRepo.init();
    final nextLevel = levelRepo.getLevel(nextId);

    // Get actual unlock cost from level data, or 0 if level doesn't exist
    final cost = nextLevel?.unlockCoins ?? 0;

    // Check if user has completed 10 questions in current level
    final completedQuestions = progress.completedQuestions[levelId] ?? [];
    final completedCount = completedQuestions.length;
    const requiredQuestions = 10;
    final hasEnoughQuestions = completedCount >= requiredQuestions;

    // Check if user has enough coins
    final hasEnoughCoins = progress.totalCoins >= cost;

    // Re-check unlock status after delay (unlock might have happened asynchronously)
    final finalProgress = ref.read(userProgressProvider);
    final finalIsUnlocked = finalProgress.maxLevelUnlocked >= nextId;

    if (!mounted) return;

    final size = MediaQuery.of(context).size;
    final scale = size.shortestSide / 375.0; // Baseline: 375dp (Standard Phone)
    
    // Compatibility aliases for existing code
    final screenSize = size;
    final screenWidth = size.width;
    final isSmallScreen = size.width < 360 || size.height < 600;

    // Responsive font sizes
    final titleFontSize = 24.0 * scale;
    final bodyFontSize = 20.0 * scale;
    final infoFontSize = 17.0 * scale;
    final smallFontSize = 14.0 * scale;
    final buttonFontSize = 20.0 * scale;

    // Responsive padding
    final outerPadding = 12.0 * scale;
    final innerPadding = 24.0 * scale;
    final contentPadding = 20.0 * scale;
    final spacing = 24.0 * scale;

    // Responsive icon sizes
    final iconSize = 32.0 * scale;
    final smallIconSize = 24.0 * scale;

    // Responsive border width
    final borderWidth = 4.0 * scale;
    final smallBorderWidth = 2.5 * scale;

    // Responsive button height
    final buttonHeight = 60.0 * scale;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (_) => Consumer(
        builder: (context, ref, child) {
          final progress = ref.watch(userProgressProvider);
          // Re-evaluate unlock conditions continuously
          final currentCoins = progress.totalCoins;
          final canUnlock = currentCoins >= cost;
          final nextLevelUnlocked = progress.maxLevelUnlocked >= nextId;

          return Dialog(
            backgroundColor: Colors.transparent,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: screenWidth * 0.9,
                maxHeight: screenSize.height * 0.85,
              ),
              child: SingleChildScrollView(
                child: Container(
                  padding: EdgeInsets.all(outerPadding),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFFFF8E1), // Cream
                        Color(0xFFFFE0B2), // Light orange
                        Color(0xFFFFCC80), // Orange
                      ],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: const Color(0xFFFF6B00), // Dark orange for stroke
                      width: borderWidth,
                    ),
                  ),
                  child: Container(
                    padding: EdgeInsets.all(innerPadding),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFFFF8E1), // Cream
                          Color(0xFFFFE0B2), // Light orange
                          Color(0xFFFFCC80), // Orange
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 3D Title with star icon
                        Container(
                          constraints: const BoxConstraints(
                            maxWidth: double.infinity,
                          ),
                          padding: EdgeInsets.symmetric(
                            vertical: isSmallScreen ? 8.0 : 12.0,
                            horizontal: isSmallScreen ? 12.0 : 16.0,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFFFFB74D), // Orange
                                Color(0xFFFF9800), // Darker orange
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFFF6B00),
                              width: borderWidth,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: EdgeInsets.all(isSmallScreen ? 6.0 : 8.0),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFE0B2),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFFF6B00),
                                    width: smallBorderWidth,
                                  ),
                                ),
                                child: Icon(
                                  Icons.star,
                                  color: const Color(0xFFFF6B00),
                                  size: iconSize,
                                ),
                              ),
                              SizedBox(width: isSmallScreen ? 6.0 : 8.0),
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    "Level Complete!",
                                    style: GoogleFonts.bangers(
                                      fontSize: titleFontSize,
                                      color: Colors.white,
                                      letterSpacing: 1.0,
                                      shadows: [
                                        Shadow(
                                          color: const Color(
                                            0xFFFF6B00,
                                          ).withOpacity(0.5),
                                          offset: const Offset(2, 2),
                                          blurRadius: 0,
                                        ),
                                      ],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: spacing),
                        // Content with 3D effect
                        Container(
                          padding: EdgeInsets.all(contentPadding),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8E1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFFFB74D),
                              width: borderWidth,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  "You found the word!",
                                  style: GoogleFonts.comicNeue(
                                    fontSize: bodyFontSize,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFFF6B00),
                                    height: 1.4,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              SizedBox(height: isSmallScreen ? 12.0 : 16.0),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  vertical: isSmallScreen ? 8.0 : 12.0,
                                  horizontal: isSmallScreen ? 12.0 : 16.0,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFFFE0B2), Color(0xFFFFCC80)],
                                  ),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color: const Color(0xFFFFB74D),
                                    width: smallBorderWidth,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(
                                        isSmallScreen ? 4.0 : 6.0,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFD54F),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFFFF6B00),
                                          width: 2,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.monetization_on,
                                        color: const Color(0xFFFF6B00),
                                        size: smallIconSize,
                                      ),
                                    ),
                                    SizedBox(width: isSmallScreen ? 6.0 : 8.0),
                                    Flexible(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          "Coins: $currentCoins",
                                          style: GoogleFonts.nunito(
                                            fontSize: infoFontSize,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFFFF6B00),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: isSmallScreen ? 12.0 : 16.0),
                              if (nextLevelUnlocked || canUnlock)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    vertical: isSmallScreen ? 8.0 : 12.0,
                                    horizontal: isSmallScreen ? 12.0 : 16.0,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFC8E6C9),
                                        Color(0xFFA5D6A7),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(
                                      color: Colors.green,
                                      width: smallBorderWidth,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.lock_open,
                                        color: Colors.green,
                                        size: smallIconSize,
                                      ),
                                      SizedBox(width: isSmallScreen ? 6.0 : 8.0),
                                      Flexible(
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            "Next Level Unlocked!",
                                            style: GoogleFonts.nunito(
                                              fontSize: infoFontSize,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green.shade800,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    vertical: isSmallScreen ? 8.0 : 12.0,
                                    horizontal: isSmallScreen ? 12.0 : 16.0,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFFFCDD2),
                                        Color(0xFFFFB3BA),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(
                                      color: Colors.red,
                                      width: smallBorderWidth,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.lock,
                                            color: Colors.red,
                                            size: smallIconSize,
                                          ),
                                          SizedBox(
                                            width: isSmallScreen ? 6.0 : 8.0,
                                          ),
                                          Flexible(
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text(
                                                "Next Level Locked",
                                                style: GoogleFonts.nunito(
                                                  fontSize: infoFontSize,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.red.shade800,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: isSmallScreen ? 6.0 : 8.0),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          _getLockedMessage(
                                            hasEnoughCoins: canUnlock,
                                            hasEnoughQuestions: hasEnoughQuestions,
                                            cost: cost,
                                            totalCoins: currentCoins,
                                            completedCount: completedCount,
                                          ),
                                          style: GoogleFonts.comicNeue(
                                            fontSize: smallFontSize,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red.shade800,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        SizedBox(height: spacing),
                        
                        // Action Buttons Logic
                        if (!nextLevelUnlocked && !canUnlock) ...[
                          // Option 1: Watch Ad
                          Container(
                            height: buttonHeight * 0.9,
                            margin: EdgeInsets.only(bottom: 12.0 * scale),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF66BB6A), Color(0xFF43A047)], // Green
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFF2E7D32),
                                width: borderWidth,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  offset: const Offset(0, 4),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  adService.showRewardedAd(
                                    (reward) {
                                      // Add 10 coins as reward
                                      ref.read(userProgressProvider.notifier).addCoins(10);
                                      _showFloatingSnackBar(
                                        "Earned +10 Coins!",
                                        icon: Icons.monetization_on,
                                        backgroundColor: Colors.green,
                                      );
                                    },
                                    onAdNotReady: () {
                                      _showFloatingSnackBar(
                                        "Ad not ready. Try again!",
                                        icon: Icons.error_outline,
                                        backgroundColor: Colors.red,
                                      );
                                    },
                                  );
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.play_circle_filled, color: Colors.white),
                                      SizedBox(width: 8.0 * scale),
                                      Flexible( // Added Flexible to prevent overflow
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            "Watch Ad (+10 Coins)",
                                            style: GoogleFonts.permanentMarker(
                                              fontSize: buttonFontSize * 0.9,
                                              color: Colors.white,
                                              letterSpacing: 1.0,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          
                          // Option 2: Replay Previous
                          Container(
                            height: buttonHeight * 0.9,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)], // Blue
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFF1565C0),
                                width: borderWidth,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  Navigator.of(context).pop(); // Just close dialog
                                  // User is back at gameplay, can open menu to replay
                                  // Ideally, we could show the replay menu directly
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Center(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      "Replay Previous",
                                      style: GoogleFonts.permanentMarker(
                                        fontSize: buttonFontSize * 0.9,
                                        color: Colors.white,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ] else
                          // Standard Continue / Next Level Button
                          Container(
                            height: buttonHeight,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: (nextLevelUnlocked || canUnlock)
                                    ? [ const Color(0xFF66BB6A), const Color(0xFF43A047) ] // Green for Next Level
                                    : [ const Color(0xFFFFB74D), const Color(0xFFFF9800) ], // Orange for Continue/Menu
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: (nextLevelUnlocked || canUnlock)
                                    ? const Color(0xFF2E7D32)
                                    : const Color(0xFFFF6B00),
                                width: borderWidth,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  // logic:
                                  // 1. Show Ad (Interstitial)
                                  // 2. On Update:
                                  //    If (nextLevelUnlocked || canUnlock) -> Go to Next Level
                                  //    Else -> Pop to Home
                                  
                                  adService.showInterstitialAd(
                                    onAdDismissed: () {
                                      if (!context.mounted) return;
                                      
                                      // Close dialog first
                                      Navigator.of(context).pop();
                                      
                                      if (nextLevelUnlocked || canUnlock) {
                                          // Navigate to next level
                                          // Replace current gameplay so back button goes to menu, not previous level
                                          Navigator.of(context).pushReplacement(
                                              MaterialPageRoute(
                                                  builder: (context) => GameplayScreen(levelId: nextId),
                                              ),
                                          );
                                      } else {
                                          // Just go back to menu
                                          if (Navigator.of(context).canPop()) {
                                              Navigator.of(context).pop();
                                          }
                                      }
                                    },
                                  );
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Center(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      (nextLevelUnlocked || canUnlock) ? "Next Level" : "Continue",
                                      style: GoogleFonts.permanentMarker(
                                        fontSize: buttonFontSize,
                                        color: Colors.white,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ).animate().scale(duration: 300.ms, curve: Curves.elasticOut),
    );
  }

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(gameplayControllerProvider.notifier).loadLevel(widget.levelId);

      // Show instructions if first time (tracked globally, or per user)
      // Using a slight delay to let the UI settle
      final progress = ref.read(userProgressProvider);
      if (!progress.instructionsSeen) {
        await Future.delayed(const Duration(seconds: 1));
        if (!mounted) return;
        await showDialog(
          context: context,
          builder: (_) => const InstructionsDialog(),
        );
        ref.read(userProgressProvider.notifier).setInstructionsSeen();
      }

      // Init ads
      adService.init();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _hideFloatingSnackBar();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameplayControllerProvider);
    final controller = ref.read(gameplayControllerProvider.notifier);
    final theme = Theme.of(context);

    // Listen for Game Over / Win / Question Complete / Time Expired
    ref.listen(gameplayControllerProvider, (prev, next) {
      if (prev?.status != next.status) {
        if (next.status == GameStatus.questionCompleted) {
          final coins = next.coinsEarnedLastQuestion;
          final questionNum = next.currentQuestionIndex + 1;
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => QuestionCompletionDialog(
              coinsEarned: coins,
              questionNumber: questionNum,
              onNext: () {
                // No ad between questions - go directly to next question
                controller.nextQuestion();
              },
            ),
          );
        } else if (next.status == GameStatus.won) {
          _confettiController.play();
          // Handle level won asynchronously
          _handleLevelWon(context, ref, next, widget.levelId, theme);
        }
      }

      // Listen for time expiration (when isTimeExpired changes from false to true)
      if (prev?.isTimeExpired != next.isTimeExpired && next.isTimeExpired) {
        // Show floating "Time Over" message - gameplay continues
        _showFloatingSnackBar(
          "Time Over!",
          backgroundColor: const Color(0xFFD32F2F),
          icon: Icons.timer_off,
          duration: const Duration(seconds: 2),
        );
      }
    });

    if (state.status == GameStatus.loading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: theme.colorScheme.primary),
        ),
      );
    }

    if (state.level == null) return const Scaffold();

    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final isTablet = screenWidth > 600;
    final isSmallScreen = screenWidth < 360 || screenSize.height < 600;
    final buttonHeight = isTablet ? 70.0 : (isSmallScreen ? 50.0 : 60.0);

    final q = state.level!.questions[state.currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
            padding: EdgeInsets.zero,
          ),
        ),
        title: Text(
          "Level ${state.level!.id}",
          style: theme.textTheme.headlineMedium?.copyWith(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () {
              // Show Menu: Replay, Instructions, Quit
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true, // Allow it to take required height
                builder: (context) {
                  final size = MediaQuery.of(context).size;
                  final scale = size.shortestSide / 375.0;
                  
                  return Container(
                    padding: EdgeInsets.only(
                      left: 8.0 * scale,
                      right: 8.0 * scale,
                      top: 8.0 * scale,
                      bottom: MediaQuery.of(context).padding.bottom + 8.0 * scale,
                    ),
                    constraints: BoxConstraints(
                      maxHeight: size.height * 0.8, // Limit max height
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFFFF8E1),
                          Color(0xFFFFE0B2),
                          Color(0xFFFFCC80),
                        ],
                      ),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(30.0 * scale),
                      ),
                      border: Border.all(
                        color: const Color(0xFFFF6B00),
                        width: 6.0 * scale,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Drag handle
                        Container(
                          width: 40 * scale,
                          height: 4 * scale,
                          margin: EdgeInsets.only(bottom: 16 * scale),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B00).withOpacity(0.4),
                            borderRadius: BorderRadius.circular(2 * scale),
                          ),
                        ),
                        Flexible(
                          child: SingleChildScrollView(
                            child: Container(
                                padding: EdgeInsets.all(24.0 * scale),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFFFFF8E1),
                                      Color(0xFFFFE0B2),
                                      Color(0xFFFFCC80),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(24.0 * scale),
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 12.0 * scale,
                                        horizontal: 16.0 * scale,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [Color(0xFFFFB74D), Color(0xFFFF9800)],
                                        ),
                                        borderRadius: BorderRadius.circular(20.0 * scale),
                                        border: Border.all(
                                          color: const Color(0xFFFF6B00),
                                          width: 4.0 * scale,
                                        ),
                                      ),
                                      child: Text(
                                        "Menu",
                                        style: GoogleFonts.bangers(
                                          fontSize: 32.0 * scale,
                                          color: Colors.white,
                                          letterSpacing: 1.5,
                                          shadows: [
                                            Shadow(
                                              color: const Color(
                                                0xFFFF6B00,
                                              ).withOpacity(0.5),
                                              offset: const Offset(2, 2),
                                              blurRadius: 0,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                        SizedBox(height: 16 * scale),
                        _buildMenuButton(
                          icon: Icons.help_outline,
                          text: "Instructions",
                          onTap: () {
                            Navigator.pop(context);
                            showDialog(
                              context: context,
                              builder: (_) => const InstructionsDialog(),
                            );
                          },
                        ),
                        SizedBox(height: 12 * scale),
                        _buildMenuButton(
                          icon: Icons.replay,
                          text: "Replay Previous",
                          onTap: () async {
                            Navigator.pop(context);

                            // Get completed questions
                            final progress = ref.read(userProgressProvider);
                            final completed =
                                progress.completedQuestions[state.level!.id] ??
                                [];

                            if (completed.isEmpty) {
                              _showFloatingSnackBar(
                                "No questions completed yet!",
                                backgroundColor: const Color(0xFF1976D2),
                                icon: Icons.info_outline,
                                duration: const Duration(seconds: 2),
                              );
                              return;
                            }

                            completed.sort(); // Ensure order

                            // Show selection dialog
                            final screenSize = MediaQuery.of(context).size;
                            // Calculate scale for the dialog
                            final scale = screenSize.shortestSide / 375.0;

                            await showDialog(
                              context: context,
                              barrierColor: Colors.black.withOpacity(0.5),
                              builder: (_) => Dialog(
                                backgroundColor: Colors.transparent,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: screenSize.width * 0.9,
                                    maxHeight: screenSize.height * 0.8,
                                  ),
                                  child: Container(
                                    padding: EdgeInsets.all(8.0 * scale),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color(0xFFFFF8E1), // Cream
                                          Color(0xFFFFE0B2), // Light orange
                                          Color(0xFFFFCC80), // Orange
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(30.0 * scale),
                                      border: Border.all(
                                        color: const Color(0xFFFF6B00),
                                        width: 6.0 * scale,
                                      ),
                                    ),
                                    child: Container(
                                      padding: EdgeInsets.all(24.0 * scale),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Color(0xFFFFF8E1),
                                            Color(0xFFFFE0B2),
                                            Color(0xFFFFCC80),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(24.0 * scale),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              vertical: 12.0 * scale,
                                              horizontal: 16.0 * scale,
                                            ),
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  Color(0xFFFFB74D),
                                                  Color(0xFFFF9800),
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(20.0 * scale),
                                              border: Border.all(
                                                color: const Color(0xFFFF6B00),
                                                width: 4.0 * scale,
                                              ),
                                            ),
                                            child: Text(
                                              "Replay Question",
                                              style: GoogleFonts.bangers(
                                                fontSize: 32.0 * scale,
                                                color: Colors.white,
                                                letterSpacing: 1.5,
                                                shadows: [
                                                  Shadow(
                                                    color: const Color(
                                                      0xFFFF6B00,
                                                    ).withOpacity(0.5),
                                                    offset: const Offset(2, 2),
                                                    blurRadius: 0,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 16.0 * scale),
                                          Flexible(
                                            child: SingleChildScrollView(
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: completed.map((qId) {
                                                  return Padding(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 8,
                                                        ),
                                                    child: Container(
                                                      height: 50,
                                                      decoration: BoxDecoration(
                                                        gradient:
                                                            const LinearGradient(
                                                              begin: Alignment
                                                                  .topLeft,
                                                              end: Alignment
                                                                  .bottomRight,
                                                              colors: [
                                                                Color(
                                                                  0xFFFFE0B2,
                                                                ),
                                                                Color(
                                                                  0xFFFFCC80,
                                                                ),
                                                              ],
                                                            ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              15,
                                                            ),
                                                        border: Border.all(
                                                          color: const Color(
                                                            0xFFFFB74D,
                                                          ),
                                                          width: 3,
                                                        ),
                                                      ),
                                                      child: Material(
                                                        color:
                                                            Colors.transparent,
                                                        child: InkWell(
                                                          onTap: () {
                                                            Navigator.pop(
                                                              context,
                                                            );
                                                            final idx = state
                                                                .level!
                                                                .questions
                                                                .indexWhere(
                                                                  (q) =>
                                                                      q.qId ==
                                                                      qId,
                                                                );
                                                            debugPrint("Replay: Clicked qId=$qId, found at index=$idx");
                                                            if (idx != -1) {
                                                              debugPrint("Replay: Jumping to question index $idx");
                                                              ref
                                                                  .read(
                                                                    gameplayControllerProvider
                                                                        .notifier,
                                                                  )
                                                                  .jumpToQuestion(
                                                                    idx,
                                                                  );
                                                            } else {
                                                              debugPrint("Replay: Error - Could not find question with qId=$qId in level ${state.level!.id}");
                                                            }
                                                          },
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                15,
                                                              ),
                                                          child: Center(
                                                            child: Text(
                                                              "Question $qId",
                                                              style: GoogleFonts.comicNeue(
                                                                fontSize: isTablet
                                                                    ? 24
                                                                    : (isSmallScreen
                                                                        ? 16
                                                                        : 18),
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color:
                                                                    const Color(
                                                                      0xFFFF6B00,
                                                                    ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 12 * scale),
                        _buildMenuButton(
                          icon: Icons.exit_to_app,
                          text: "Exit Level",
                          onTap: () {
                            Navigator.pop(context);
                            // Show ad when exiting to home page
                            adService.showInterstitialAd(
                              onAdDismissed: () {
                                if (context.mounted) {
                                  Navigator.pop(context);
                                }
                              },
                            );
                          },
                        ),
                        SizedBox(height: 16 * scale),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
    },
  ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.monetization_on,
                      color: Colors.yellowAccent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "${ref.watch(userProgressProvider).totalCoins}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Background Image
            Positioned.fill(
              child: Image.asset(
                'assets/game_play_page Backgound.png',
                fit: BoxFit.cover,
                repeat: ImageRepeat.noRepeat,
                opacity: const AlwaysStoppedAnimation<double>(0.7),
              ),
            ),
            
            if (MediaQuery.of(context).orientation == Orientation.landscape)
              // LANDSCAPE LAYOUT (Side-by-side)
              Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left Side: Clues, Timer, Buttons (Scrollable if needed)
                  Expanded(
                    flex: 4, 
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                             // Clue Section
                            Container(
                              margin: const EdgeInsets.all(12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    "Question ${state.currentQuestionIndex + 1}/${state.level!.questions.length}",
                                    style: TextStyle(
                                      color: theme.colorScheme.secondary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    q.question,
                                    style: theme.textTheme.headlineSmall?.copyWith(
                                      fontSize: isTablet ? 32 : 18, 
                                      color: theme.colorScheme.onSurface,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 12),
                                  // Answer Blanks
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(q.answer.length, (index) {
                                      String char = "";
                                      bool filled = false;
                                      if (state.hintPositions.containsKey(index)) {
                                          int tapIdx = state.hintPositions[index]!;
                                          int r = tapIdx ~/ 6;
                                          int c = tapIdx % 6;
                                          char = state.currentGrid[r][c];
                                          filled = true;
                                      } else if (index < state.selectedIndices.length) {
                                          int tapIdx = state.selectedIndices[index];
                                          int r = tapIdx ~/ 6;
                                          int c = tapIdx % 6;
                                          char = state.currentGrid[r][c];
                                          filled = true;
                                      }
                                      return Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 4),
                                        width: isTablet ? 50 : 32,
                                        height: isTablet ? 60 : 40,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          border: Border(
                                            bottom: BorderSide(
                                              width: 3,
                                              color: filled ? const Color(0xFFFF6B00) : Colors.grey.shade300,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          char,
                                          style: TextStyle(
                                            fontSize: isTablet ? 32 : 20,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFFFF6B00),
                                          ),
                                        ).animate(target: filled ? 1 : 0).scale(duration: 200.ms, curve: Curves.easeOutBack),
                                      );
                                    }),
                                  ),
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
                                color: state.timeLeft < 10
                                    ? Colors.red
                                    : theme.colorScheme.tertiary,
                              ).animate(target: state.timeLeft < 10 ? 1 : 0).shake(hz: 2),
                            ),

                            // Action Buttons
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  // Reset Button
                                  Expanded(child: _buildActionButton(
                                      text: "Reset",
                                      icon: Icons.refresh_rounded,
                                      color: const Color(0xFFFFE0B2),
                                      textColor: const Color(0xFFFF6B00),
                                      height: buttonHeight,
                                      onTap: () => controller.clearSelection(),
                                  )),
                                  const SizedBox(width: 8),
                                  // Hint Button
                                  Expanded(child: _buildActionButton(
                                      text: _isHintAdLoading ? "Loading..." : "Hint",
                                      icon: _isHintAdLoading ? null : Icons.lightbulb_outline,
                                      color: (state.hintsUsed >= 1 || _isHintAdLoading) ? Colors.grey.shade400 : const Color(0xFFFFB74D),
                                      textColor: (state.hintsUsed >= 1 || _isHintAdLoading) ? Colors.grey.shade600 : Colors.white,
                                      height: buttonHeight,
                                      isLoading: _isHintAdLoading,
                                      onTap: () => _handleHintTap(state, q, controller),
                                  )),
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
                    ),
                  ),

                  // Right Side: Grid (Maximize space)
                  Expanded(
                    flex: 6,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                             // Use min of width/height to ensure square grid fits
                            final availableSize = min(constraints.maxWidth, constraints.maxHeight);
                             // Center text
                            final horizontalPadding = (constraints.maxWidth - availableSize) / 2;
                            final verticalPadding = (constraints.maxHeight - availableSize) / 2;
                            final tileSize = (availableSize - (5 * 8)) / 6;

                            return Padding(
                               padding: EdgeInsets.symmetric(
                                horizontal: max(0, horizontalPadding),
                                vertical: max(0, verticalPadding),
                              ),
                              child: Stack(
                                children: [
                                  IgnorePointer(
                                    child: CustomPaint(
                                      size: Size(constraints.maxWidth, constraints.maxHeight),
                                      painter: SelectionPathPainter(
                                        selectedIndices: state.selectedIndices,
                                        tileSize: tileSize,
                                        spacing: 8.0,
                                        color: const Color(0xFFFF6B00),
                                      ),
                                    ),
                                  ),
                                  GridView.builder(
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: 36,
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 6,
                                      crossAxisSpacing: 8,
                                      mainAxisSpacing: 8,
                                    ),
                                    itemBuilder: (context, index) {
                                      return _buildGridTile(index, state, controller, tileSize);
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else
              // PORTRAIT LAYOUT (Existing Column)
              Column(
                children: [
                  // Clue Section
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    width: double.infinity,
                    child: Column(
                      children: [
                        Text(
                          "Question ${state.currentQuestionIndex + 1}/${state.level!.questions.length}",
                          style: TextStyle(
                            color: theme.colorScheme.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          q.question,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontSize: isTablet
                                ? 32
                                : (isSmallScreen ? 18 : 22),
                            color: theme.colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        // Answer Blanks with Animation
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(q.answer.length, (index) {
                            String char = "";
                            bool filled = false;
                            if (state.hintPositions.containsKey(index)) {
                                int tapIdx = state.hintPositions[index]!;
                                int r = tapIdx ~/ 6;
                                int c = tapIdx % 6;
                                char = state.currentGrid[r][c];
                                filled = true;
                            } else if (index < state.selectedIndices.length) {
                                int tapIdx = state.selectedIndices[index];
                                int r = tapIdx ~/ 6;
                                int c = tapIdx % 6;
                                char = state.currentGrid[r][c];
                                filled = true;
                            }
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: isTablet ? 60 : (isSmallScreen ? 32 : 40),
                              height: isTablet ? 70 : (isSmallScreen ? 40 : 50),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    width: isSmallScreen ? 2 : 3,
                                    color: filled
                                        ? const Color(0xFFFF6B00)
                                        : Colors.grey.shade300,
                                  ),
                                ),
                              ),
                              child: Text(
                                    char,
                                    style: TextStyle(
                                      fontSize: isTablet
                                          ? 40
                                          : (isSmallScreen ? 20 : 28),
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFFF6B00),
                                    ),
                                  ).animate(target: filled ? 1 : 0).scale(
                                    duration: 200.ms,
                                    curve: Curves.easeOutBack,
                                  ),
                            );
                          }),
                        ),
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
                      color: state.timeLeft < 10
                          ? Colors.red
                          : theme.colorScheme.tertiary,
                    ).animate(target: state.timeLeft < 10 ? 1 : 0).shake(hz: 2),
                  ),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // Calculate available size (min of width/height to keep it square)
                          final availableSize = min(
                            constraints.maxWidth,
                            constraints.maxHeight,
                          );
                          // Center the grid
                          final horizontalPadding =
                              (constraints.maxWidth - availableSize) / 2;
                          final verticalPadding =
                              (constraints.maxHeight - availableSize) / 2;

                          final tileSize = (availableSize - (5 * 8)) / 6;

                          return Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: max(0, horizontalPadding),
                              vertical: max(0, verticalPadding),
                            ),
                            child: Stack(
                              children: [
                                // Draw connecting line behind the boxes
                              IgnorePointer(
                                child: CustomPaint(
                                  size: Size(
                                    constraints.maxWidth,
                                    constraints.maxHeight,
                                  ),
                                  painter: SelectionPathPainter(
                                    selectedIndices: state.selectedIndices,
                                    tileSize: tileSize,
                                    spacing: 8.0,
                                    color: const Color(0xFFFF6B00),
                                  ),
                                ),
                              ),
                              // Letter boxes on top
                              GridView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: 36,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 6,
                                      crossAxisSpacing: 8,
                                      mainAxisSpacing: 8,
                                    ),
                                itemBuilder: (context, index) {
                                   return _buildGridTile(index, state, controller, tileSize);
                                },
                              ),
                            ],
                          ));
                        },
                      ),
                    ),
                  ),

                  // Action Buttons
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Reset Button
                        Expanded(child: _buildActionButton(
                           text: "Reset",
                           icon: Icons.refresh_rounded,
                           color: const Color(0xFFFFE0B2),
                           textColor: const Color(0xFFFF6B00),
                           height: buttonHeight,
                           onTap: () => controller.clearSelection(),
                        )),
                        const SizedBox(width: 8),
                         // Hint Button
                        Expanded(child: _buildActionButton(
                           text: _isHintAdLoading ? "Loading..." : "Hint",
                           icon: _isHintAdLoading ? null : Icons.lightbulb_outline,
                           color: (state.hintsUsed >= 1 || _isHintAdLoading) ? Colors.grey.shade400 : const Color(0xFFFFB74D),
                           textColor: (state.hintsUsed >= 1 || _isHintAdLoading) ? Colors.grey.shade600 : Colors.white,
                           height: buttonHeight,
                           isLoading: _isHintAdLoading,
                           onTap: () => _handleHintTap(state, q, controller),
                        )),
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
                colors: const [
                  Colors.green,
                  Colors.blue,
                  Colors.pink,
                  Colors.orange,
                  Colors.purple,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // HELPER METHODS FOR CLEANER CODE
  
  Widget _buildGridTile(int index, GameplayState state, GameplayController controller, double tileSize) {
        final r = index ~/ 6;
        final c = index % 6;
        final letter = state.currentGrid[r][c];
        final isSelected = state.selectedIndices.contains(index);

        // Determine font size based on screen
        final screenSize = MediaQuery.of(context).size;
        final isTablet = screenSize.width > 600;
        final isSmall = screenSize.width < 360 || screenSize.height < 600;

        return GestureDetector(
          onTap: () => controller.onTileTap(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFFFF8E1) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                width: 3,
                color: isSelected ? const Color(0xFFFF6B00) : Colors.grey.shade200,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? const Color(0xFFFF6B00).withOpacity(0.4)
                      : Colors.black.withOpacity(0.05),
                  blurRadius: isSelected ? 8 : 4,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              letter.toUpperCase(),
              style: TextStyle(
                fontSize: tileSize * 0.5, // Responsive: 50% of tile size
                fontWeight: FontWeight.w900,
                color: isSelected ? const Color(0xFFFF6B00) : Colors.grey.shade700,
              ),
            ),
          ).animate().scale(delay: (30 * index).ms, duration: 400.ms, curve: Curves.easeOutBack),
        );
  }

  Widget _buildActionButton({
    required String text,
    IconData? icon,
    required Color color,
    required Color textColor,
    required double height,
    required VoidCallback? onTap,
    bool isLoading = false,
  }) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: (onTap == null) ? [] : [
             BoxShadow(
               color: Colors.black.withOpacity(0.2),
               blurRadius: 8,
               offset: const Offset(0, 4),
             ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                   const SizedBox(
                     width: 20, height: 20,
                     child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                   )
                else if (icon != null)
                   Icon(icon, color: textColor, size: 24),
                
                if (!isLoading && icon != null) const SizedBox(width: 8),
                Text(
                  text,
                  style: GoogleFonts.comicNeue(
                    fontSize: height * 0.35, // Responsive: 35% of button height
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }

  void _handleHintTap(GameplayState state, Question q, GameplayController controller) {
      if (state.hintsUsed >= 1) {
        if (mounted) _showFloatingSnackBar("You have used all available hints!", backgroundColor: const Color(0xFF1976D2), icon: Icons.block);
        return;
      }

      final path = q.answerPlacement.path;
      if (path.length < 3) {
        if (mounted) _showFloatingSnackBar("Word is too short for hint!", backgroundColor: const Color(0xFF1976D2), icon: Icons.info_outline);
        return;
      }

      final middleLetters = path.sublist(1, path.length - 1);
      if (middleLetters.isEmpty) return;

      final random = Random();
      final middleLetterIndex = random.nextInt(middleLetters.length);
      final selectedHintLetter = middleLetters[middleLetterIndex];
      final hintPositionInPath = 1 + middleLetterIndex;
      final row = selectedHintLetter['row']!;
      final col = selectedHintLetter['col']!;
      final hintLetter = q.grid[row][col].toUpperCase();
      final pathUpToHint = path.sublist(0, hintPositionInPath + 1);

      void showHint() {
        if (!mounted) return;
        _showFloatingSnackBar("Hint: Letter '$hintLetter' is marked!", backgroundColor: const Color(0xFF00796B), icon: Icons.lightbulb);
        controller.selectHintLetterAtPosition(pathUpToHint, hintPositionInPath);
      }

      setState(() { _isHintAdLoading = true; });
      controller.pauseTimer();

      ref.read(adManagerProvider).showRewarded(
        (reward) { debugPrint('Reward earned: ${reward.amount} ${reward.type}'); },
        onAdDismissed: () {
          if (mounted) setState(() { _isHintAdLoading = false; });
          controller.resumeTimer();
          showHint();
        },
        onAdNotReady: () {
          if (mounted) setState(() { _isHintAdLoading = false; });
          controller.resumeTimer();
          if (mounted) _showFloatingSnackBar("Ad is loading. Please try again.", backgroundColor: const Color(0xFF616161), icon: Icons.hourglass_empty);
        },
      );
  }

  Widget _buildMenuButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    final screenSize = MediaQuery.of(context).size;
    final scale = screenSize.shortestSide / 375.0;
    
    final height = 60.0 * scale;
    final iconSize = 28.0 * scale;
    final fontSize = 20.0 * scale;

    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFE0B2), Color(0xFFFFCC80)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFB74D), width: 4),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Row(
            children: [
              const SizedBox(width: 16),
              Icon(icon, color: const Color(0xFFFF6B00), size: iconSize),
              const SizedBox(width: 16),
              Text(
                text,
                style: GoogleFonts.bubblegumSans(
                  fontSize: fontSize,
                  color: const Color(0xFFFF6B00),
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SelectionPathPainter extends CustomPainter {
  final List<int> selectedIndices;
  final double tileSize;
  final double spacing;
  final Color color;

  SelectionPathPainter({
    required this.selectedIndices,
    required this.tileSize,
    required this.spacing,
    required this.color,
  });

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

    // Helper function to get box center
    Offset getBoxCenter(int index) {
      final r = index ~/ 6;
      final c = index % 6;
      final x = c * (tileSize + spacing) + tileSize / 2;
      final y = r * (tileSize + spacing) + tileSize / 2;
      return Offset(x, y);
    }

    // Helper function to get edge point of a box based on direction
    Offset getEdgePoint(Offset center, Offset direction) {
      // Normalize direction
      final length = direction.distance;
      if (length == 0) return center;
      final normalized = direction / length;

      // Calculate edge point (half tileSize away from center in the direction)
      return center + normalized * (tileSize / 2);
    }

    for (int i = 0; i < selectedIndices.length; i++) {
      final currentCenter = getBoxCenter(selectedIndices[i]);

      if (i == 0) {
        // For the first box, if there's a next box, start from edge toward next box
        if (selectedIndices.length > 1) {
          final nextCenter = getBoxCenter(selectedIndices[i + 1]);
          final direction = nextCenter - currentCenter;
          final startEdge = getEdgePoint(currentCenter, direction);
          path.moveTo(startEdge.dx, startEdge.dy);
        } else {
          // Only one box, start from center
          path.moveTo(currentCenter.dx, currentCenter.dy);
        }
      } else {
        // Get previous box center
        final prevCenter = getBoxCenter(selectedIndices[i - 1]);

        // Calculate direction from previous to current
        final direction = currentCenter - prevCenter;

        // Get entry point to current box (edge facing the previous box)
        final entryPoint = getEdgePoint(currentCenter, -direction);

        // Draw line directly to the entry edge of current box
        path.lineTo(entryPoint.dx, entryPoint.dy);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(SelectionPathPainter oldDelegate) {
    return oldDelegate.selectedIndices != selectedIndices;
  }
}
