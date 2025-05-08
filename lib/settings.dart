import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'logs_page.dart';
import 'login_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  List<String> _posTerminals = [];
  String? _selectedTerminal;

  @override
  void initState() {
    super.initState();
    _fetchTerminals();
    _loadSelectedTerminal();
  }

  Future<void> _fetchTerminals() async {
    // Replace with your API call if needed
    final String data = await rootBundle.loadString('assets/terminals.json');
    final List<dynamic> terminals = jsonDecode(data);
    setState(() {
      _posTerminals = terminals.cast<String>();
      if (_posTerminals.isNotEmpty && _selectedTerminal == null) {
        _selectedTerminal = _posTerminals[0];
      }
    });
  }

  Future<void> _loadSelectedTerminal() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedTerminal = prefs.getString('selected_terminal') ?? _posTerminals[0];
    });
  }

  Future<void> _saveSelectedTerminal(String? terminal) async {
    final prefs = await SharedPreferences.getInstance();
    if (terminal != null) {
      await prefs.setString('selected_terminal', terminal);
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
                _saveSelectedTerminal(value);
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'POS Terminal',
              ),
            ),
            const SizedBox(height: 32),
            // Add logs button
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('Transaction Logs'),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LogsPage()),
                );
              },
            ),
            const Divider(),
            // Add sign out button
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign Out'),
              onTap: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              },
            ),
            // You can add more settings widgets here
          ],
        ),
      ),
    );
  }
}