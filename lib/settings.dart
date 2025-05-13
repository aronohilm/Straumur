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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[50]!, Colors.white],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
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
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          labelText: 'POS Terminal',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: Icon(Icons.receipt_long, color: Colors.blue[800]),
                  title: const Text('Transaction Logs'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LogsPage()),
                    );
                  },
                ),
              ),
              const Divider(height: 32),
              // Sign Out button removed as login page is deactivated
              // You can add more settings widgets here
            ],
          ),
        ),
      ),
    );
  }
}