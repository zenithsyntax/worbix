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

    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final isTablet = screenWidth > 600;
    final isSmallScreen = screenWidth < 360;

    // Responsive font sizes
    final titleFontSize = isTablet ? 28.0 : (isSmallScreen ? 18.0 : 22.0);
    final bodyFontSize = isTablet ? 22.0 : (isSmallScreen ? 16.0 : 20.0);
    final infoFontSize = isTablet ? 19.0 : (isSmallScreen ? 15.0 : 17.0);
    final smallFontSize = isTablet ? 16.0 : (isSmallScreen ? 12.0 : 14.0);
    final buttonFontSize = isTablet ? 24.0 : (isSmallScreen ? 18.0 : 20.0);

    // Responsive padding
    final outerPadding = isTablet ? 12.0 : (isSmallScreen ? 4.0 : 8.0);
    final innerPadding = isTablet ? 32.0 : (isSmallScreen ? 16.0 : 24.0);
    final contentPadding = isTablet ? 24.0 : (isSmallScreen ? 12.0 : 20.0);
    final spacing = isTablet ? 32.0 : (isSmallScreen ? 16.0 : 24.0);

    // Responsive icon sizes
    final iconSize = isTablet ? 32.0 : (isSmallScreen ? 20.0 : 28.0);
    final smallIconSize = isTablet ? 28.0 : (isSmallScreen ? 20.0 : 24.0);

    // Responsive border width
    final borderWidth = isTablet ? 5.0 : (isSmallScreen ? 3.0 : 4.0);
    final smallBorderWidth = isTablet ? 4.0 : (isSmallScreen ? 2.0 : 3.0);

    // Responsive button height
    final buttonHeight = isTablet ? 70.0 : (isSmallScreen ? 50.0 : 60.0);

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (_) => Dialog(
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
                                      "Coins: ${state.currentCoins}",
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
                          if (finalIsUnlocked)
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
                                        hasEnoughCoins: hasEnoughCoins,
                                        hasEnoughQuestions: hasEnoughQuestions,
                                        cost: cost,
                                        totalCoins: finalProgress.totalCoins,
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
                    // Continue button with 3D effect
                    Container(
                      height: buttonHeight,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFFFB74D), Color(0xFFFF9800)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFFF6B00),
                          width: borderWidth,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).pop();
                            // Show ad after level completion, then go back to home
                            adService.showInterstitialAd(
                              onAdDismissed: () {
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                }
                              },
                            );
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                "Continue",
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
        // Show simple "Time Over" message - gameplay continues
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Time Over"),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
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
                builder: (_) => Container(
                  padding: const EdgeInsets.all(8),
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
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                    border: Border.all(
                      color: const Color(0xFFFF6B00),
                      width: 6,
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(24),
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
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFFFB74D), Color(0xFFFF9800)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFFF6B00),
                              width: 4,
                            ),
                          ),
                          child: Text(
                            "Menu",
                            style: GoogleFonts.bangers(
                              fontSize: 24,
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
                        const SizedBox(height: 16),
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
                        const SizedBox(height: 12),
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
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("No questions completed yet!"),
                                ),
                              );
                              return;
                            }

                            completed.sort(); // Ensure order

                            // Show selection dialog
                            final screenSize = MediaQuery.of(context).size;
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
                                    padding: const EdgeInsets.all(8),
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
                                        color: const Color(0xFFFF6B00),
                                        width: 6,
                                      ),
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.all(24),
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
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                              horizontal: 16,
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
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color: const Color(0xFFFF6B00),
                                                width: 4,
                                              ),
                                            ),
                                            child: Text(
                                              "Replay Question",
                                              style: GoogleFonts.bangers(
                                                fontSize: 24,
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
                                          const SizedBox(height: 16),
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
                                                            if (idx != -1) {
                                                              ref
                                                                  .read(
                                                                    gameplayControllerProvider
                                                                        .notifier,
                                                                  )
                                                                  .jumpToQuestion(
                                                                    idx,
                                                                  );
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
                                                                fontSize: 18,
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
                        const SizedBox(height: 12),
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
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
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
                          fontSize: 22,
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

                          // Check if there's a hint at this position
                          if (state.hintPositions.containsKey(index)) {
                            int tapIdx = state.hintPositions[index]!;
                            int r = tapIdx ~/ 6;
                            int c = tapIdx % 6;
                            char = state.currentGrid[r][c];
                            filled = true;
                          } else if (index < state.selectedIndices.length) {
                            // Otherwise check selected indices
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
                              border: Border(
                                bottom: BorderSide(
                                  width: 3,
                                  color: filled
                                      ? const Color(0xFFFF6B00)
                                      : Colors.grey.shade300,
                                ),
                              ),
                            ),
                            child:
                                Text(
                                      char,
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFFFF6B00),
                                      ),
                                    )
                                    .animate(target: filled ? 1 : 0)
                                    .scale(
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
                        final gridWidth = constraints.maxWidth;
                        final tileSize = (gridWidth - (5 * 8)) / 6;

                        return Stack(
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
                                final r = index ~/ 6;
                                final c = index % 6;
                                final letter = state.currentGrid[r][c];
                                final isSelected = state.selectedIndices
                                    .contains(index);

                                return GestureDetector(
                                  onTap: () => controller.onTileTap(index),
                                  child:
                                      AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 150,
                                        ),
                                        curve: Curves.easeOut,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? const Color(0xFFFFF8E1)
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            width: 3,
                                            color: isSelected
                                                ? const Color(0xFFFF6B00)
                                                : Colors.grey.shade200,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: isSelected
                                                  ? const Color(
                                                      0xFFFF6B00,
                                                    ).withOpacity(0.4)
                                                  : Colors.black.withOpacity(
                                                      0.05,
                                                    ),
                                              blurRadius: isSelected ? 8 : 4,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          letter.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w900,
                                            color: isSelected
                                                ? const Color(0xFFFF6B00)
                                                : Colors.grey.shade700,
                                          ),
                                        ),
                                      ).animate().scale(
                                        delay: (30 * index).ms,
                                        duration: 400.ms,
                                        curve: Curves.easeOutBack,
                                      ),
                                );
                              },
                            ),
                          ],
                        );
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
                      Expanded(
                        child: Container(
                          height: 60,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE0B2),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
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
                              onTap: () => controller.clearSelection(),
                              borderRadius: BorderRadius.circular(20),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.refresh_rounded,
                                    color: Color(0xFFFF6B00),
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Reset",
                                    style: GoogleFonts.comicNeue(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFFF6B00),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Hint Button
                      Expanded(
                        child: Container(
                          height: 60,
                          margin: const EdgeInsets.only(left: 8),
                          decoration: BoxDecoration(
                            color: state.hintsUsed >= 1
                                ? Colors.grey.shade400
                                : const Color(0xFFFFB74D),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: state.hintsUsed >= 1
                                ? []
                                : [
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
                              onTap: state.hintsUsed >= 1
                                  ? null
                                  : () {
                                      // Check if hint limit reached (only 1 hint per question)
                                      if (state.hintsUsed >= 1) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                "You have used all available hints for this question!",
                                              ),
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                        }
                                        return;
                                      }

                                      // Get hint data - middle letters only (exclude first and last)
                                      final path = q.answerPlacement.path;

                                      // Need at least 3 letters to have middle letters
                                      if (path.length < 3) {
                                        // If word is too short, show a message
                                        if (mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                "Word is too short for hint!",
                                              ),
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                        }
                                        return;
                                      }

                                      // Get middle letters (exclude first and last)
                                      final middleLetters = path.sublist(
                                        1,
                                        path.length - 1,
                                      );

                                      if (middleLetters.isEmpty) return;

                                      // Randomly select ONE middle letter
                                      final random = Random();
                                      final middleLetterIndex = random.nextInt(
                                        middleLetters.length,
                                      );
                                      final selectedHintLetter =
                                          middleLetters[middleLetterIndex];

                                      // Find the position of this letter in the original path
                                      // middleLetters starts at index 1 of path, so we need to add 1
                                      final hintPositionInPath =
                                          1 + middleLetterIndex;

                                      // Get the letter for the snackbar message
                                      final row = selectedHintLetter['row']!;
                                      final col = selectedHintLetter['col']!;
                                      final hintLetter = q.grid[row][col]
                                          .toUpperCase();

                                      // Create a list with all path positions up to and including the hint
                                      final pathUpToHint = path.sublist(
                                        0,
                                        hintPositionInPath + 1,
                                      );

                                      // Function to show hint
                                      void showHint() {
                                        if (!mounted) return;

                                        // Show snackbar with single letter
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              "Hint: Letter '$hintLetter' is marked!",
                                            ),
                                            duration: const Duration(
                                              seconds: 2,
                                            ),
                                          ),
                                        );

                                        // Auto-select the hint letter at the correct position
                                        controller.selectHintLetterAtPosition(
                                          pathUpToHint,
                                          hintPositionInPath,
                                        );
                                      }

                                      // Pause timer when ad is shown
                                      controller.pauseTimer();

                                      // Show rewarded ad first
                                      ref
                                          .read(adManagerProvider)
                                          .showRewarded(
                                            (reward) {
                                              // Reward earned callback (for tracking)
                                              debugPrint(
                                                'Reward earned: ${reward.amount} ${reward.type}',
                                              );
                                            },
                                            onAdDismissed: () {
                                              // Resume timer when ad is dismissed
                                              controller.resumeTimer();
                                              // Hint shown when ad is dismissed (user watched it)
                                              showHint();
                                            },
                                            onAdNotReady: () {
                                              // Resume timer if ad is not ready
                                              controller.resumeTimer();
                                              // If ad is not ready, show a message
                                              if (mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      "Ad is loading. Please try again in a moment.",
                                                    ),
                                                    duration: Duration(
                                                      seconds: 2,
                                                    ),
                                                  ),
                                                );
                                              }
                                            },
                                          );
                                    },
                              borderRadius: BorderRadius.circular(20),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.lightbulb_outline,
                                    color: state.hintsUsed >= 1
                                        ? Colors.grey.shade600
                                        : Colors.white,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Hint",
                                    style: GoogleFonts.comicNeue(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: state.hintsUsed >= 1
                                          ? Colors.grey.shade600
                                          : Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
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

  Widget _buildMenuButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 60,
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
              Icon(icon, color: const Color(0xFFFF6B00), size: 28),
              const SizedBox(width: 16),
              Text(
                text,
                style: GoogleFonts.bubblegumSans(
                  fontSize: 20,
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
