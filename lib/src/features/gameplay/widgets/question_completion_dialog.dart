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
              maxWidth: MediaQuery.of(context).size.width * 0.9,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
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
                  color: const Color(0xFFFF6B00), // Dark orange for stroke
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
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
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
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Container(
                          //   padding: const EdgeInsets.all(8),
                          //   decoration: BoxDecoration(
                          //     color: const Color(0xFFFFE0B2),
                          //     shape: BoxShape.circle,
                          //     border: Border.all(
                          //       color: const Color(0xFFFF6B00),
                          //       width: 3,
                          //     ),
                          //   ),
                          //   child: const Text(
                          //     "🎉",
                          //     style: TextStyle(fontSize: 28),
                          //   ),
                          // ),
                          // const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              "Congratulations!",
                              style: GoogleFonts.bangers(
                                fontSize: 28,
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
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Content with 3D effect
                    Flexible(
                      child: SingleChildScrollView(
                        child: Container(
                          padding: const EdgeInsets.all(20),
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
                              Text(
                                "Question ${widget.questionNumber} Completed!",
                                style: GoogleFonts.comicNeue(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFFF6B00),
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "You solved the puzzle!",
                                style: GoogleFonts.comicNeue(
                                  fontSize: 16,
                                  color: const Color(0xFFFF6B00),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFFFE0B2), Color(0xFFFFCC80)],
                                  ),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color: const Color(0xFFFFB74D),
                                    width: 3,
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
                                          width: 2,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.monetization_on,
                                        color: Color(0xFFFF6B00),
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "+${widget.coinsEarned}",
                                      style: GoogleFonts.nunito(
                                        fontSize: 24,
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
                    const SizedBox(height: 24),
                    // Next Question button with 3D effect
                    Container(
                      height: 60,
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
                          onTap: () {
                            Navigator.of(context).pop();
                            widget.onNext();
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Center(
                            child: Text(
                              "Next Question",
                              style: GoogleFonts.permanentMarker(
                                fontSize: 20,
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
