import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../levels/level_repository.dart';
import '../store/user_progress_provider.dart';
import '../store/user_progress_model.dart';
import '../gameplay/gameplay_screen.dart';
import '../settings/settings_dialog.dart';
import '../ads/ad_service.dart';
import '../ads/ad_manager.dart';
import '../levels/level_model.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isNoInternetDialogShowing = false;

  @override
  void initState() {
    super.initState();
    // Precache the background image for fast loading
    WidgetsBinding.instance.addPostFrameCallback((_) {
      precacheImage(
        const AssetImage('assets/home_page_backgorund.png'),
        context,
      );
      // Check internet connectivity
      _checkInternetConnection();
      // Listen for connectivity changes
      _listenToConnectivityChanges();
    });
  }

  bool _hasNoInternet(List<ConnectivityResult> results) {
    // Only show popup when there's absolutely no network connection
    // Don't show for slow/low internet - only when completely disconnected
    return results.isEmpty ||
        (results.length == 1 && results.first == ConnectivityResult.none);
  }

  void _listenToConnectivityChanges() {
    Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      if (_hasNoInternet(results)) {
        // Completely no internet connection (0 internet)
        if (mounted && !_isNoInternetDialogShowing) {
          _showNoInternetDialog();
        }
      } else {
        // Internet connection exists (even if slow) - automatically close the dialog
        if (mounted && _isNoInternetDialogShowing) {
          _isNoInternetDialogShowing = false;
          Navigator.of(context).pop();
        }
      }
    });
  }

  Future<void> _checkInternetConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    // Only show popup when there's completely no network connection (0 internet)
    // Don't show for slow/low internet connections
    if (_hasNoInternet(connectivityResult)) {
      // No internet connection at all
      if (mounted) {
        _showNoInternetDialog();
      }
    }
  }

  void _showNoInternetDialog() {
    if (_isNoInternetDialogShowing) return; // Prevent multiple dialogs

    _isNoInternetDialogShowing = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final screenSize = MediaQuery.of(context).size;
        final screenWidth = screenSize.width;
        final screenHeight = screenSize.height;
        final isSmallScreen = screenWidth < 360 || screenHeight < 640;
        final isMediumScreen = screenWidth >= 360 && screenWidth < 600;

        double titleFontSize = isSmallScreen ? 20 : (isMediumScreen ? 24 : 26);
        double messageFontSize = isSmallScreen
            ? 14
            : (isMediumScreen ? 16 : 18);
        double buttonFontSize = isSmallScreen ? 16 : (isMediumScreen ? 18 : 20);

        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
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
                width: 6,
              ),
            ),
            child: Container(
              padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
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
                  // Icon and Title
                  Container(
                    padding: EdgeInsets.symmetric(
                      vertical: isSmallScreen ? 8 : 12,
                      horizontal: isSmallScreen ? 12 : 16,
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
                        width: 4,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE0B2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFFF6B00),
                              width: 3,
                            ),
                          ),
                          child: Icon(
                            Icons.wifi_off,
                            color: const Color(0xFFFF6B00),
                            size: isSmallScreen ? 24 : 32,
                          ),
                        ),
                        SizedBox(width: isSmallScreen ? 8 : 12),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              "No Internet Connection",
                              style: GoogleFonts.bangers(
                                fontSize: titleFontSize,
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
                              textAlign: TextAlign.center,
                              maxLines: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 16 : 24),
                  // Message
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 12 : 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFFFB74D),
                        width: 4,
                      ),
                    ),
                    child: Text(
                      "Please check your internet connection and try again.",
                      style: GoogleFonts.nunito(
                        fontSize: messageFontSize,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFFF6B00),
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 16 : 24),
                  // Retry Button
                  Container(
                    width: double.infinity,
                    height: isSmallScreen ? 50 : 60,
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
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          _isNoInternetDialogShowing = false;
                          Navigator.of(context).pop();
                          await _checkInternetConnection();
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.refresh,
                                color: Colors.white,
                                size: isSmallScreen ? 22 : 28,
                              ),
                              SizedBox(width: isSmallScreen ? 6 : 8),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  "Retry",
                                  style: GoogleFonts.permanentMarker(
                                    fontSize: buttonFontSize,
                                    color: Colors.white,
                                    letterSpacing: 1.2,
                                  ),
                                  maxLines: 1,
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
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final levelsAsync = ref.watch(levelsProvider);
    final userProgress = ref.watch(userProgressProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Image.asset(
          'assets/worbix-wordmark.png',
          height: 40,
          fit: BoxFit.contain,
        ),
        centerTitle: false,
        automaticallyImplyLeading: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.4),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.monetization_on,
                  color: Colors.yellowAccent,
                  size: 24,
                ),
                const SizedBox(width: 6),
                Text(
                  "${userProgress.totalCoins}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 18,
                    shadows: [
                      Shadow(
                        color: Colors.orange,
                        offset: Offset(1, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.4),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: IconButton(
              icon: const Icon(Icons.settings, color: Colors.white, size: 24),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => const SettingsDialog(),
                );
              },
              tooltip: 'Settings',
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/home_page_backgorund.png'),
            fit: BoxFit.cover,
            repeat: ImageRepeat.noRepeat,
            opacity: 0.7,
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

    // Get previous level info for unlock criteria
    final userProgress = ref.read(userProgressProvider);
    final previousLevelId = level.id - 1;
    final previousLevelCompleted =
        userProgress.completedQuestions[previousLevelId] ?? [];
    final completedCount = previousLevelCompleted.length;
    const requiredQuestions = 10;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) {
        // Get screen size for responsive text
        final screenSize = MediaQuery.of(context).size;
        final screenWidth = screenSize.width;
        final screenHeight = screenSize.height;
        final isSmallScreen = screenWidth < 360 || screenHeight < 640;
        final isMediumScreen = screenWidth >= 360 && screenWidth < 600;

        // Calculate responsive font sizes
        double titleFontSize = isSmallScreen ? 22 : (isMediumScreen ? 26 : 28);
        double criteriaFontSize = isSmallScreen
            ? 14
            : (isMediumScreen ? 16 : 18);
        double buttonFontSize = isSmallScreen ? 16 : (isMediumScreen ? 18 : 20);

        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
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
                width: 6,
              ),
            ),
            child: Container(
              padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
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
                  // 3D Title with lock icon
                  Container(
                    padding: EdgeInsets.symmetric(
                      vertical: isSmallScreen ? 8 : 12,
                      horizontal: isSmallScreen ? 12 : 16,
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
                        width: 4,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE0B2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFFF6B00),
                              width: 3,
                            ),
                          ),
                          child: Icon(
                            Icons.lock,
                            color: const Color(0xFFFF6B00),
                            size: isSmallScreen ? 24 : 32,
                          ),
                        ),
                        SizedBox(width: isSmallScreen ? 8 : 12),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              "Level ${level.id} Locked!",
                              style: GoogleFonts.bangers(
                                fontSize: titleFontSize,
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
                              textAlign: TextAlign.center,
                              maxLines: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 16 : 24),
                  // Content with 3D effect - Unlock Criteria
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 12 : 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFFFB74D),
                        width: 4,
                      ),
                    ),
                    child: Column(
                      children: [
                        // Unlock Criteria Title
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "To Unlock Level ${level.id}:",
                            style: GoogleFonts.comicNeue(
                              fontSize: criteriaFontSize + 2,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFFF6B00),
                              height: 1.3,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 12 : 16),
                        // Criteria 1: Complete 10 questions
                        Container(
                          padding: EdgeInsets.symmetric(
                            vertical: isSmallScreen ? 8 : 10,
                            horizontal: isSmallScreen ? 10 : 12,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF2196F3),
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                color: const Color(0xFF2196F3),
                                size: isSmallScreen ? 18 : 20,
                              ),
                              SizedBox(width: isSmallScreen ? 6 : 8),
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    "Complete 10 questions in Level $previousLevelId",
                                    style: GoogleFonts.nunito(
                                      fontSize: criteriaFontSize,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1976D2),
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 8 : 10),
                        // Progress indicator for questions
                        Container(
                          padding: EdgeInsets.symmetric(
                            vertical: isSmallScreen ? 6 : 8,
                            horizontal: isSmallScreen ? 10 : 12,
                          ),
                          decoration: BoxDecoration(
                            color: completedCount >= requiredQuestions
                                ? Colors.green.shade50
                                : Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: completedCount >= requiredQuestions
                                  ? Colors.green
                                  : Colors.orange,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                completedCount >= requiredQuestions
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                color: completedCount >= requiredQuestions
                                    ? Colors.green
                                    : Colors.orange,
                                size: isSmallScreen ? 16 : 18,
                              ),
                              SizedBox(width: isSmallScreen ? 6 : 8),
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    "Progress: $completedCount / $requiredQuestions questions",
                                    style: GoogleFonts.nunito(
                                      fontSize: criteriaFontSize - 1,
                                      fontWeight: FontWeight.w600,
                                      color: completedCount >= requiredQuestions
                                          ? Colors.green.shade800
                                          : Colors.orange.shade800,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 10 : 12),
                        // Criteria 2: Have enough coins
                        Container(
                          padding: EdgeInsets.symmetric(
                            vertical: isSmallScreen ? 8 : 10,
                            horizontal: isSmallScreen ? 10 : 12,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFE0B2), Color(0xFFFFCC80)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFFFB74D),
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: EdgeInsets.all(isSmallScreen ? 4 : 6),
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
                                  size: isSmallScreen ? 18 : 20,
                                ),
                              ),
                              SizedBox(width: isSmallScreen ? 6 : 8),
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    "Have $unlockCost coins (You have: $currentCoins)",
                                    style: GoogleFonts.nunito(
                                      fontSize: criteriaFontSize,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFFF6B00),
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 16 : 24),
                  // Two buttons with 3D effect
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Cancel button
                      Expanded(
                        child: Container(
                          height: isSmallScreen ? 50 : 60,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFFFE0B2), Color(0xFFFFCC80)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFFFB74D),
                              width: 4,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                Navigator.of(context).pop();
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Center(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    "Cancel",
                                    style: GoogleFonts.bubblegumSans(
                                      fontSize: buttonFontSize,
                                      color: const Color(0xFFFF6B00),
                                      letterSpacing: 1.2,
                                    ),
                                    maxLines: 1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: isSmallScreen ? 12 : 16),
                      // Watch Ad button
                      Expanded(
                        child: Container(
                          height: isSmallScreen ? 50 : 60,
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
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () async {
                                // Get ScaffoldMessenger and Navigator before closing dialog
                                final scaffoldMessenger = ScaffoldMessenger.of(
                                  context,
                                );
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
                                await Future.delayed(
                                  const Duration(milliseconds: 500),
                                );

                                // Show rewarded ad
                                ref
                                    .read(adManagerProvider)
                                    .showRewarded(
                                      (reward) {
                                        // Reward earned - add 10 coins only (do not unlock level)
                                        ref
                                            .read(userProgressProvider.notifier)
                                            .addCoins(10);
                                        // Check if coins are enough to unlock next sequential level
                                        ref
                                            .read(userProgressProvider.notifier)
                                            .checkAutoUnlock();
                                        // Hide loading snackbar and show success
                                        scaffoldMessenger.hideCurrentSnackBar();
                                        scaffoldMessenger.showSnackBar(
                                          SnackBar(
                                            content: Text("+10 coins earned!"),
                                            backgroundColor: Colors.green,
                                            duration: const Duration(
                                              seconds: 2,
                                            ),
                                          ),
                                        );
                                      },
                                      onAdDismissed: () {
                                        // Ad dismissed - no action needed, reward already handled in reward callback
                                      },
                                      onAdNotReady: () {
                                        // Hide loading snackbar and show error with retry option
                                        scaffoldMessenger.hideCurrentSnackBar();
                                        scaffoldMessenger.showSnackBar(
                                          SnackBar(
                                            content: const Text(
                                              "Ad failed to load. Please check your internet connection and try again.",
                                            ),
                                            duration: const Duration(
                                              seconds: 4,
                                            ),
                                            backgroundColor: Colors.orange,
                                            action: SnackBarAction(
                                              label: 'Retry',
                                              textColor: Colors.white,
                                              onPressed: () {
                                                // Retry loading and showing the ad
                                                ref
                                                    .read(adManagerProvider)
                                                    .loadRewarded();
                                                // Show the ad again after a short delay
                                                Future.delayed(const Duration(seconds: 2), () {
                                                  ref
                                                      .read(adManagerProvider)
                                                      .showRewarded(
                                                        (reward) {
                                                          ref
                                                              .read(
                                                                userProgressProvider
                                                                    .notifier,
                                                              )
                                                              .addCoins(10);
                                                          // Check if coins are enough to unlock next sequential level
                                                          ref
                                                              .read(
                                                                userProgressProvider
                                                                    .notifier,
                                                              )
                                                              .checkAutoUnlock();
                                                          scaffoldMessenger.showSnackBar(
                                                            SnackBar(
                                                              content: Text(
                                                                "+10 coins earned!",
                                                              ),
                                                              backgroundColor:
                                                                  Colors.green,
                                                              duration:
                                                                  const Duration(
                                                                    seconds: 2,
                                                                  ),
                                                            ),
                                                          );
                                                        },
                                                        onAdDismissed: () {
                                                          // Ad dismissed - no action needed, reward already handled in reward callback
                                                        },
                                                        onAdNotReady: () {
                                                          scaffoldMessenger
                                                              .showSnackBar(
                                                                const SnackBar(
                                                                  content: Text(
                                                                    "Ad still not ready. Please try again later.",
                                                                  ),
                                                                  duration:
                                                                      Duration(
                                                                        seconds:
                                                                            3,
                                                                      ),
                                                                  backgroundColor:
                                                                      Colors
                                                                          .red,
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
                              borderRadius: BorderRadius.circular(20),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.play_circle_filled,
                                    color: Colors.white,
                                    size: isSmallScreen ? 22 : 28,
                                  ),
                                  SizedBox(width: isSmallScreen ? 6 : 8),
                                  Flexible(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        "Watch Ad",
                                        style: GoogleFonts.permanentMarker(
                                          fontSize: buttonFontSize,
                                          color: Colors.white,
                                          letterSpacing: 1.2,
                                        ),
                                        maxLines: 1,
                                      ),
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
                ],
              ),
            ),
          ),
        );
      },
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
    final isTablet = screenWidth >= 600;

    // Calculate responsive icon size
    final iconSize = _calculateIconSize(screenWidth, screenHeight, isTablet);

    // Calculate path positions for levels
    final nodePositions = _calculateNodePositions(
      widget.levels.length,
      screenWidth,
      screenHeight,
      iconSize,
    );

    // Calculate total height needed
    final totalHeight = _calculateTotalHeight(
      widget.levels.length,
      screenHeight,
      screenWidth,
      iconSize,
    );

    return SingleChildScrollView(
      controller: _scrollController,
      child: SizedBox(
        width: screenWidth,
        height: totalHeight,
        child: Stack(
          children: [
            // Background path - removed
            // CustomPaint(
            //   size: Size(screenWidth, totalHeight),
            //   painter: RoadmapPathPainter(
            //     nodeCount: widget.levels.length,
            //     nodePositions: nodePositions,
            //   ),
            // ),

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
                left: position.dx - (iconSize / 2),
                top: position.dy - (iconSize / 2),
                child:
                    LevelNode(
                          level: level,
                          isLocked: isLocked,
                          hasEnoughCoins:
                              hasEnoughCoins &&
                              level.id ==
                                  widget.userProgress.maxLevelUnlocked + 1,
                          onTap: () => widget.onLevelTap(level),
                          iconSize: iconSize,
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

  // Calculate responsive icon size based on screen dimensions
  double _calculateIconSize(
    double screenWidth,
    double screenHeight,
    bool isTablet,
  ) {
    // Base size for mobile phones
    double baseSize = 110.0;

    // For tablets, scale up proportionally
    if (isTablet) {
      // Scale based on screen width, but keep it reasonable
      final scaleFactor = math.min(
        screenWidth / 360.0,
        1.5,
      ); // Max 1.5x for tablets
      baseSize = 110.0 * scaleFactor;
    } else {
      // For smaller phones, scale down slightly
      if (screenWidth < 360) {
        baseSize = 100.0;
      } else if (screenWidth < 400) {
        baseSize = 105.0;
      }
    }

    return baseSize;
  }

  List<Offset> _calculateNodePositions(
    int levelCount,
    double screenWidth,
    double screenHeight,
    double iconSize,
  ) {
    final positions = <Offset>[];
    // Fixed spacing between nodes for consistency across all screen types
    // This ensures the same distance between icons on mobile and tablets
    final nodeSpacing = 160.0;
    // Account for icon size when calculating path width to prevent edge cutoff
    final iconPadding = iconSize / 2;
    final pathWidth = (screenWidth - (iconPadding * 2)) * 0.65;
    final startX = iconPadding + (screenWidth - (iconPadding * 2)) * 0.175;
    final topPadding = 180.0;

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
        // Second level - slightly more space from first level
        baseY = topPadding + (nodeSpacing * 0.7);
      } else if (i == 2) {
        // Third level - extra space after second level
        baseY = topPadding + (nodeSpacing * 0.7) + (nodeSpacing * 1.3);
      } else {
        // Increased spacing for remaining levels
        baseY =
            topPadding +
            (nodeSpacing * 0.7) +
            (nodeSpacing * 1.3) +
            (nodeSpacing * (i - 2) * 1.0);
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

      // Clamp x position to ensure icons stay within screen bounds
      // Icons are positioned at (x - iconSize/2), so we need padding
      final minX = iconSize / 2;
      final maxX = screenWidth - (iconSize / 2);
      x = x.clamp(minX, maxX);

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

  double _calculateTotalHeight(
    int levelCount,
    double screenHeight,
    double screenWidth,
    double iconSize,
  ) {
    if (levelCount == 0) return screenHeight;

    // Calculate the actual Y position of the last level using the same logic as _calculateNodePositions
    final nodeSpacing = 160.0;
    final topPadding = 180.0;

    double lastLevelY;
    if (levelCount == 1) {
      lastLevelY = topPadding;
    } else if (levelCount == 2) {
      lastLevelY = topPadding + (nodeSpacing * 0.7);
    } else if (levelCount == 3) {
      lastLevelY = topPadding + (nodeSpacing * 0.7) + (nodeSpacing * 1.3);
    } else {
      lastLevelY =
          topPadding +
          (nodeSpacing * 0.7) +
          (nodeSpacing * 1.3) +
          (nodeSpacing * (levelCount - 2) * 1.0);
    }

    // Add vertical wave offset (max possible from the wave calculation)
    final maxVerticalWave = nodeSpacing * 0.18; // From verticalWave calculation
    final maxDepthOffset =
        nodeSpacing * 0.08 * 0.6; // From depthOffset calculation
    final maxVerticalOffset = maxVerticalWave + maxDepthOffset;
    lastLevelY += maxVerticalOffset;

    // Add bottom padding (icon size / 2 + some margin) instead of excessive multiplier
    final bottomPadding = (iconSize / 2) + 40; // Small padding after last icon

    return lastLevelY + bottomPadding;
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
      // Positioned(
      //   left: screenWidth * 0.5 - 20,
      //   top: totalHeight * 0.6,
      //   child: _CrosswordIcon(size: 35),
      // ),
      // // Bottom area - Crossword icon
      // Positioned(
      //   left: screenWidth * 0.3,
      //   top: totalHeight * 0.5,
      //   child: _CrosswordIcon(size: 28),
      // ),
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
  final double iconSize;

  const LevelNode({
    super.key,
    required this.level,
    required this.isLocked,
    required this.hasEnoughCoins,
    required this.onTap,
    this.iconSize = 110.0,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate responsive font size based on icon size
    final fontSize = iconSize * 0.4;
    final iconIconSize = iconSize * 0.4;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: iconSize,
        height: iconSize,
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
              ? Icon(
                  Icons.lock,
                  color: Colors.white.withOpacity(0.7),
                  size: iconIconSize,
                )
              : Text(
                  "${level.id}",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    shadows: const [
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
