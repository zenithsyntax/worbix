import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360 || screenSize.height < 640;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF9800),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "Privacy Policy",
          style: GoogleFonts.bangers(
            fontSize: isSmallScreen ? 22 : 28,
            color: Colors.white,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFF8E1), // Cream
              Color(0xFFFFE0B2), // Light orange
              Color(0xFFFFCC80), // Orange
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
          child: Container(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFFB74D), width: 3),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSection(
                  "Data Collection",
                  "Worbix collects minimal data necessary for app functionality:\n\n"
                      "• Game progress and level completion data\n"
                      "• Coins and achievements\n"
                      "• Settings preferences (sound, etc.)\n\n"
                      "All data is stored locally on your device.",
                  isSmallScreen,
                ),
                const SizedBox(height: 24),
                _buildSection(
                  "Data Storage",
                  "All your game data, including progress, coins, and unlocked levels, "
                      "is stored locally on your device using secure local storage. "
                      "We do not transmit your data to external servers.",
                  isSmallScreen,
                ),
                const SizedBox(height: 24),
                _buildSection(
                  "Clear Data",
                  "You can clear all your data at any time through the Settings menu. "
                      "This will permanently delete:\n\n"
                      "• All game progress\n"
                      "• All coins and achievements\n"
                      "• All unlocked levels\n\n"
                      "This action cannot be undone.",
                  isSmallScreen,
                ),
                const SizedBox(height: 24),
                _buildSection(
                  "Third-Party Services",
                  "Worbix may use third-party advertising services that may collect "
                      "anonymous usage data for ad personalization. You can manage ad preferences "
                      "through your device settings.",
                  isSmallScreen,
                ),
                const SizedBox(height: 24),
                _buildSection(
                  "Children's Privacy",
                  "Worbix is designed to be safe for children. We do not knowingly collect "
                      "personal information from children under 13. All data collection is limited "
                      "to what is necessary for game functionality.",
                  isSmallScreen,
                ),
                const SizedBox(height: 24),
                _buildSection(
                  "Changes to Privacy Policy",
                  "We may update this Privacy Policy from time to time. Any changes will be "
                      "reflected in this document. Continued use of the app after changes constitutes "
                      "acceptance of the updated policy.",
                  isSmallScreen,
                ),
                const SizedBox(height: 24),
                _buildSection(
                  "Contact",
                  "If you have any questions about this Privacy Policy, please contact us through "
                      "the app settings or support channels.",
                  isSmallScreen,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE0B2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFFF6B00),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: const Color(0xFFFF6B00),
                        size: isSmallScreen ? 20 : 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Last updated: ${DateTime.now().year}",
                          style: GoogleFonts.comicNeue(
                            fontSize: isSmallScreen ? 14 : 16,
                            color: const Color(0xFFFF6B00),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content, bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 12 : 16,
            vertical: isSmallScreen ? 8 : 12,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFB74D), Color(0xFFFF9800)],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFF6B00), width: 2),
          ),
          child: Text(
            title,
            style: GoogleFonts.bangers(
              fontSize: isSmallScreen ? 18 : 22,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: GoogleFonts.comicNeue(
            fontSize: isSmallScreen ? 14 : 16,
            color: const Color(0xFF424242),
            height: 1.6,
          ),
        ),
      ],
    );
  }
}
