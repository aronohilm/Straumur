import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Mock list of POS terminals; replace with your API data as needed
  final List<String> _posTerminals = [
    'POS-001 (Front Desk)',
    'POS-002 (Bar)',
    'POS-003 (Drive Thru)',
    'POS-004 (Mobile Cart)',
  ];

  String? _selectedTerminal;

  @override
  void initState() {
    super.initState();
    // Optionally set a default selected terminal
    if (_posTerminals.isNotEmpty) {
      _selectedTerminal = _posTerminals[0];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.blue[800],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select POS Terminal',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedTerminal,
              items: _posTerminals
                  .map((terminal) => DropdownMenuItem(
                        value: terminal,
                        child: Text(terminal),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedTerminal = value;
                });
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'POS Terminal',
              ),
            ),
            const SizedBox(height: 32),
            // You can add more settings widgets here
          ],
        ),
      ),
    );
  }
}