import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _audioEnabled = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        elevation: 0,
        title: Text("Settings", style: theme.textTheme.headlineMedium?.copyWith(color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        color: theme.colorScheme.surface,
        child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 120, 16, 16),
            child: ListView(
                children: [
                    _SettingsTile(
                        icon: _audioEnabled ? Icons.volume_up : Icons.volume_off,
                        title: "Sound Effects",
                        trailing: Switch(
                            value: _audioEnabled,
                            activeColor: theme.colorScheme.primary,
                            onChanged: (val) {
                                setState(() => _audioEnabled = val);
                                // TODO: Persist preference
                            }
                        ),
                    ),
                    const SizedBox(height: 16),
                    _SettingsTile(
                        icon: Icons.privacy_tip,
                        title: "Privacy Policy",
                        onTap: () {
                            // TODO: Launch URL
                        },
                    ),
                    const SizedBox(height: 16),
                    _SettingsTile(
                        icon: Icons.child_care,
                        title: "Parental Gate",
                        onTap: () {
                             showDialog(context: context, builder: (_) => AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                title: const Text("Parental Check"),
                                content: const Text("What is 3 + 4?"),
                                actions: [
                                    TextButton(onPressed: () => Navigator.pop(context), child: const Text("5")),
                                    TextButton(onPressed: () {
                                         Navigator.pop(context);
                                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Verified!")));
                                    }, child: const Text("7")),
                                    TextButton(onPressed: () => Navigator.pop(context), child: const Text("9")),
                                ],
                            ));
                        },
                    ),
                    const SizedBox(height: 32),
                    const Center(child: Text("Version 1.0.0", style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold))),
                ],
            ),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
    final IconData icon;
    final String title;
    final Widget? trailing;
    final VoidCallback? onTap;
    
    const _SettingsTile({required this.icon, required this.title, this.trailing, this.onTap});
    
    @override
    Widget build(BuildContext context) {
        return Container(
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0,2))]
            ),
            child: ListTile(
                leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        shape: BoxShape.circle
                    ),
                    child: Icon(icon, color: Theme.of(context).colorScheme.primary)
                ),
                title: Text(title, style: Theme.of(context).textTheme.titleLarge),
                trailing: trailing ?? const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: onTap,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            )
        );
    }
}
