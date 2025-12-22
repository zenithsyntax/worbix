import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class InstructionsDialog extends StatelessWidget {
  const InstructionsDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scale = size.shortestSide / 375.0;
    final isSmallScreen = size.width < 360 || size.height < 600;

    // Responsive font sizes based on screen size
    final titleFontSize = isSmallScreen ? 24.0 * scale : 28.0 * scale;
    final stepFontSize = isSmallScreen ? 13.0 * scale : 16.0 * scale;
    final buttonFontSize = isSmallScreen ? 18.0 * scale : 20.0 * scale;
    final iconSize = isSmallScreen ? 20.0 * scale : 24.0 * scale;
    final titleIconSize = isSmallScreen ? 22.0 * scale : 32.0 * scale;

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
                  horizontal: isSmallScreen ? 8.0 * scale : 16.0 * scale,
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(
                        isSmallScreen ? 6.0 * scale : 8.0 * scale,
                      ),
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
                        size: titleIconSize,
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 8.0 * scale : 12.0 * scale),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          "How to Play",
                          style: GoogleFonts.bangers(
                            fontSize: titleFontSize,
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
                          textAlign: TextAlign.center,
                        ),
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
                        _step(
                          Icons.touch_app,
                          'Connect adjacent letters.',
                          scale,
                          stepFontSize,
                          iconSize,
                        ),
                        _step(
                          Icons.subdirectory_arrow_right,
                          'Form the answer word.',
                          scale,
                          stepFontSize,
                          iconSize,
                        ),
                        _step(
                          Icons.timer,
                          'Solve faster to earn more coins!',
                          scale,
                          stepFontSize,
                          iconSize,
                        ),
                        _step(
                          Icons.loop,
                          'Cannot cross your own path.',
                          scale,
                          stepFontSize,
                          iconSize,
                        ),
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
    );
  }

  Widget _step(
    IconData icon,
    String text,
    double scale,
    double fontSize,
    double iconSize,
  ) {
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
            child: Icon(icon, color: const Color(0xFFFF6B00), size: iconSize),
          ),
          SizedBox(width: 12.0 * scale),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.comicNeue(
                fontSize: fontSize,
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
