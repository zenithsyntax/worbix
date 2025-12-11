import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../store/user_progress_provider.dart';
import '../gameplay/widgets/instructions_dialog.dart';

class SettingsDialog extends ConsumerWidget {
  const SettingsDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProgress = ref.watch(userProgressProvider);
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360 || screenSize.height < 640;

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
              // Title
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
                        Icons.settings,
                        color: const Color(0xFFFF6B00),
                        size: isSmallScreen ? 24 : 32,
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 8 : 12),
                    Text(
                      "Settings",
                      style: GoogleFonts.bangers(
                        fontSize: isSmallScreen ? 22 : 28,
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
                    ),
                  ],
                ),
              ),
              SizedBox(height: isSmallScreen ? 16 : 24),
              // Sound Effects Toggle
              _SettingsOption(
                icon: userProgress.soundEnabled ? Icons.volume_up : Icons.volume_off,
                title: "Sound Effects",
                trailing: Switch(
                  value: userProgress.soundEnabled,
                  activeColor: const Color(0xFFFF6B00),
                  onChanged: (val) {
                    ref.read(userProgressProvider.notifier).setSoundEnabled(val);
                  },
                ),
                isSmallScreen: isSmallScreen,
              ),
              SizedBox(height: isSmallScreen ? 12 : 16),
              // Show Instructions Again
              _SettingsOption(
                icon: Icons.help_outline,
                title: "Show Instructions Again",
                onTap: () {
                  Navigator.of(context).pop();
                  showDialog(
                    context: context,
                    builder: (_) => const InstructionsDialog(),
                  );
                },
                isSmallScreen: isSmallScreen,
              ),
              SizedBox(height: isSmallScreen ? 12 : 16),
              // Privacy Policy
              _SettingsOption(
                icon: Icons.privacy_tip,
                title: "Privacy Policy",
                onTap: () async {
                  // TODO: Replace with actual privacy policy URL
                  final url = Uri.parse('https://www.example.com/privacy-policy');
                  try {
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Could not open privacy policy'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  }
                },
                isSmallScreen: isSmallScreen,
              ),
              SizedBox(height: isSmallScreen ? 12 : 16),
              // Clear Data
              _SettingsOption(
                icon: Icons.delete_outline,
                title: "Clear Data",
                onTap: () {
                  Navigator.of(context).pop();
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      title: const Text("Clear All Data?"),
                      content: const Text(
                        "This will delete all your progress, coins, and unlocked levels. This action cannot be undone.",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () {
                            ref.read(userProgressProvider.notifier).clearData();
                            Navigator.of(context).pop();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('All data cleared'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          },
                          child: const Text(
                            "Clear",
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                isSmallScreen: isSmallScreen,
              ),
              SizedBox(height: isSmallScreen ? 16 : 24),
              // Close button
              Container(
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
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(20),
                    child: Center(
                      child: Text(
                        "Close",
                        style: GoogleFonts.permanentMarker(
                          fontSize: isSmallScreen ? 18 : 20,
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
}

class _SettingsOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isSmallScreen;

  const _SettingsOption({
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFB74D),
          width: 3,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE0B2),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFFF6B00),
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              color: const Color(0xFFFF6B00),
              size: isSmallScreen ? 20 : 24,
            ),
          ),
          SizedBox(width: isSmallScreen ? 12 : 16),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.comicNeue(
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFFF6B00),
              ),
            ),
          ),
          if (trailing != null) trailing!,
          if (onTap != null && trailing == null)
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFFFF6B00),
            ),
        ],
      ),
    );
  }
}

