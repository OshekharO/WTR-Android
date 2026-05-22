import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Card(child: ListTile(leading: Icon(Icons.translate), title: Text('Language'), subtitle: Text('English'))),
          Card(child: ListTile(leading: Icon(Icons.text_fields), title: Text('Reader font size'), subtitle: Text('Coming soon'))),
          Card(child: ListTile(leading: Icon(Icons.dark_mode_outlined), title: Text('Theme'), subtitle: Text('Uses system theme'))),
        ],
      ),
    );
  }
}
