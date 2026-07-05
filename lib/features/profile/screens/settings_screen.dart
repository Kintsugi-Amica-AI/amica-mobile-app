import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: const [
          SwitchListTile(
            value: true,
            onChanged: null,
            title: Text('Enable safety notifications'),
          ),
          SwitchListTile(
            value: true,
            onChanged: null,
            title: Text('Enable stealth voice SOS'),
          ),
        ],
      ),
    );
  }
}
