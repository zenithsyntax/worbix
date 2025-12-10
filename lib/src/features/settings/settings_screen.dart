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
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text("Sound Effects"),
            value: _audioEnabled,
            onChanged: (val) {
              setState(() => _audioEnabled = val);
              // TODO: Persist preference
            },
          ),
          const Divider(),
          ListTile(
            title: const Text("Privacy Policy"),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
                // TODO: Launch URL
            },
          ),
          ListTile(
            title: const Text("Parental Gate"),
            trailing: const Icon(Icons.lock),
            onTap: () {
                // Simple math challenge
                showDialog(context: context, builder: (_) => AlertDialog(
                    title: const Text("Parental Check"),
                    content: const Text("What is 3 + 4?"),
                    actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text("5")),
                        TextButton(onPressed: () {
                             Navigator.pop(context);
                             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Verified!")));
                             // Navigate to protected settings
                        }, child: const Text("7")),
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text("9")),
                    ],
                ));
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("Version 1.0.0",textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          )
        ],
      ),
    );
  }
}
