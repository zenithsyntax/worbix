import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class InstructionsDialog extends StatelessWidget {
  const InstructionsDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.shortestSide / 375.0;

    return Dialog(
      backgroundColor: Colors.transparent,
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
            color: const Color(0xFFFF6B00), // Dark orange for stroke
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
                Color(0xFFFFF8E1), // Cream
                Color(0xFFFFE0B2), // Light orange
                Color(0xFFFFCC80), // Orange
              ],
            ),
            borderRadius: BorderRadius.circular(24.0 * scale),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 3D Title
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
                      Color(0xFFFFB74D), // Orange
                      Color(0xFFFF9800), // Darker orange
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20.0 * scale),
                  border: Border.all(
                    color: const Color(0xFFFF6B00),
                    width: 4.0 * scale,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.0 * scale),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE0B2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFFF6B00),
                          width: 3.0 * scale,
                        ),
                      ),
                      child: Icon(
                        Icons.help_outline,
                        color: const Color(0xFFFF6B00),
                        size: 32.0 * scale,
                      ),
                    ),
                    SizedBox(width: 12.0 * scale),
                    Flexible(
                      child: Text(
                        "How to Play",
                        style: GoogleFonts.bangers(
                          fontSize: 28.0 * scale,
                          color: Colors.white,
                          letterSpacing: 1.5,
                          shadows: [
                            Shadow(
                              color: const Color(0xFFFF6B00).withOpacity(0.5),
                              offset: const Offset(2, 2),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.0 * scale),
              // Content with 3D effect
              Flexible(
                child: SingleChildScrollView(
                  child: Container(
                    padding: EdgeInsets.all(20.0 * scale),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(20.0 * scale),
                      border: Border.all(
                        color: const Color(0xFFFFB74D),
                        width: 4.0 * scale,
                      ),
                    ),
                    child: Column(
                      children: [
                        _step(Icons.touch_app, 'Connect adjacent letters.', scale),
                        _step(Icons.subdirectory_arrow_right, 'Form the answer word.', scale),
                        _step(Icons.timer, 'Solve faster to earn more coins!', scale),
                        _step(Icons.loop, 'Cannot cross your own path.', scale),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 24.0 * scale),
              // Got it button with 3D effect
              Container(
                height: 60.0 * scale,
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
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(20.0 * scale),
                    child: Center(
                      child: Text(
                        "Got it!",
                        style: GoogleFonts.permanentMarker(
                          fontSize: 20.0 * scale,
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
    );
  }

  Widget _step(IconData icon, String text, double scale) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0 * scale),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.0 * scale),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE0B2),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFFF6B00),
                width: 2.0 * scale,
              ),
            ),
            child: Icon(icon, color: const Color(0xFFFF6B00), size: 24.0 * scale),
          ),
          SizedBox(width: 12.0 * scale),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.comicNeue(
                fontSize: 16.0 * scale,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFFF6B00),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
