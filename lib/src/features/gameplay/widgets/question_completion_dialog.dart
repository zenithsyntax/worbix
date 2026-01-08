import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'package:google_fonts/google_fonts.dart';

class QuestionCompletionDialog extends StatefulWidget {
  final int coinsEarned;
  final int questionNumber;
  final VoidCallback onNext;

  const QuestionCompletionDialog({
    Key? key,
    required this.coinsEarned,
    required this.questionNumber,
    required this.onNext,
  }) : super(key: key);

  @override
  State<QuestionCompletionDialog> createState() =>
      _QuestionCompletionDialogState();
}

class _QuestionCompletionDialogState extends State<QuestionCompletionDialog> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scale = size.shortestSide / 375.0; // Baseline: 375dp (Standard Phone)

    // Responsive Dimensions
    final dialogMaxWidth = size.width * 0.9;
    final dialogMaxHeight = size.height * 0.85;

    // Responsive Font Sizes
    final titleFontSize = 28.0 * scale;
    final bodyFontSize = 20.0 * scale;
    final subBodyFontSize = 16.0 * scale;
    final coinFontSize = 24.0 * scale;
    final buttonFontSize = 20.0 * scale;

    // Responsive Padding & Spacing
    final outerPadding = 8.0 * scale;
    final innerPadding = 24.0 * scale;
    final contentPadding = 20.0 * scale;
    final titlePaddingV = 12.0 * scale;
    final titlePaddingH = 16.0 * scale;
    final coinContainerPaddingV = 12.0 * scale;
    final coinContainerPaddingH = 16.0 * scale;
    final spacingLarge = 24.0 * scale;
    final spacingMedium = 16.0 * scale;
    final spacingSmall = 8.0 * scale;

    // Responsive Borders & Sizes
    final outerBorderWidth = 6.0 * scale;
    final innerBorderWidth = 4.0 * scale;
    final coinBorderWidth = 3.0 * scale;
    final coinIconBorderWidth = 2.0 * scale;
    final buttonBorderWidth = 4.0 * scale;
    final buttonHeight = 60.0 * scale;
    final coinIconSize = 24.0 * scale;

    return Stack(
      children: [
        Align(
          alignment: Alignment.center,
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
        Dialog(
          backgroundColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: dialogMaxWidth,
              maxHeight: dialogMaxHeight,
            ),
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
                  width: outerBorderWidth,
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
                    // 3D Title
                    Container(
                      constraints: const BoxConstraints(
                        maxWidth: double.infinity,
                      ),
                      padding: EdgeInsets.symmetric(
                        vertical: titlePaddingV,
                        horizontal: titlePaddingH,
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
                          width: innerBorderWidth,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                "Congratulations!",
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
                    SizedBox(height: spacingLarge),
                    // Content with 3D effect
                    Flexible(
                      child: SingleChildScrollView( // Made scrollable for safety
                        child: Container(
                          padding: EdgeInsets.all(contentPadding),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8E1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFFFB74D),
                              width: innerBorderWidth,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min, // Added min
                            children: [
                              Text(
                                "Question ${widget.questionNumber} Completed!",
                                style: GoogleFonts.comicNeue(
                                  fontSize: bodyFontSize,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFFF6B00),
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: spacingSmall),
                              Text(
                                "You solved the puzzle!",
                                style: GoogleFonts.comicNeue(
                                  fontSize: subBodyFontSize,
                                  color: const Color(0xFFFF6B00),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: spacingMedium),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  vertical: coinContainerPaddingV,
                                  horizontal: coinContainerPaddingH,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFFFE0B2), Color(0xFFFFCC80)],
                                  ),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color: const Color(0xFFFFB74D),
                                    width: coinBorderWidth,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFD54F),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFFFF6B00),
                                          width: coinIconBorderWidth,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.monetization_on,
                                        color: const Color(0xFFFF6B00),
                                        size: coinIconSize,
                                      ),
                                    ),
                                    SizedBox(width: spacingSmall),
                                    Text(
                                      "+${widget.coinsEarned}",
                                      style: GoogleFonts.nunito(
                                        fontSize: coinFontSize,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFFFF6B00),
                                      ),
                                    ),
                                  ],
                                ),
                              ).animate().scale(
                                duration: 500.ms,
                                curve: Curves.elasticOut,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: spacingLarge),
                    // Next Question button with 3D effect
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
                          width: buttonBorderWidth,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).pop();
                            widget.onNext();
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Center(
                            child: Text(
                              "Next Question",
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
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
