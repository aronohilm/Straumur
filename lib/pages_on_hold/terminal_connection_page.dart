import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';

class TerminalConnectionPage extends StatefulWidget {
  const TerminalConnectionPage({super.key});

  @override
  State<TerminalConnectionPage> createState() => _TerminalConnectionPageState();
}

class _TerminalConnectionPageState extends State<TerminalConnectionPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _endpointController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();
  
  List<String> _terminals = [];
  String? _selectedTerminal;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSavedSettings();
  }

  Future<void> _loadSavedSettings() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      setState(() {
        _endpointController.text = prefs.getString('endpoint') ?? 'https://terminal-api-test.adyen.com/sync';
        _apiKeyController.text = prefs.getString('api_key') ?? '';
        _selectedTerminal = prefs.getString('selected_terminal');
      });
      
      // If we have endpoint and API key, fetch terminals
      if (_endpointController.text.isNotEmpty && _apiKeyController.text.isNotEmpty) {
        await _fetchTerminals();
      }
    } catch (e) {
      _showToast('Error loading settings: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchTerminals() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Endpoint for getting terminals
      final terminalsEndpoint = _endpointController.text.replaceAll('/sync', '/terminals');
      
      final response = await http.get(
        Uri.parse(terminalsEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'X-API-Key': _apiKeyController.text,
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['terminals'] != null && data['terminals'] is List) {
          final List<dynamic> terminalsList = data['terminals'];
          
          setState(() {
            _terminals = terminalsList
                .map((terminal) => terminal['terminal_id'].toString())
                .toList()
                .cast<String>();
                
            // If we have terminals and no selection yet, select the first one
            if (_terminals.isNotEmpty && _selectedTerminal == null) {
              _selectedTerminal = _terminals[0];
            } else if (_selectedTerminal != null && !_terminals.contains(_selectedTerminal)) {
              // If the previously selected terminal is no longer available
              _selectedTerminal = _terminals.isNotEmpty ? _terminals[0] : null;
            }
          });
          
          _showToast('Found ${_terminals.length} terminals');
        } else {
          setState(() {
            _errorMessage = 'No terminals found in the response';
            _terminals = [];
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Error fetching terminals: ${response.statusCode} - ${response.body}';
          _terminals = [];
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error: $e';
        _terminals = [];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setString('endpoint', _endpointController.text);
      await prefs.setString('api_key', _apiKeyController.text);
      
      if (_selectedTerminal != null) {
        await prefs.setString('selected_terminal', _selectedTerminal!);
      }
      
      _showToast('Settings saved successfully');
      
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      _showToast('Error saving settings: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.black87,
      textColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('POS Terminal Connection'),
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
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
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
                            'API Connection Settings',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _endpointController,
                            decoration: InputDecoration(
                              labelText: 'Endpoint URL',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter an endpoint URL';
                              }
                              if (!value.startsWith('http')) {
                                return 'URL must start with http:// or https://';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _apiKeyController,
                            decoration: InputDecoration(
                              labelText: 'API Key',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter an API key';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _isLoading ? null : _fetchTerminals,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Fetch Terminals'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[800],
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator()),
                  if (_errorMessage != null)
                    Card(
                      color: Colors.red[100],
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red[900]),
                        ),
                      ),
                    ),
                  if (_terminals.isNotEmpty)
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
                              'Select Terminal',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _selectedTerminal,
                              items: _terminals
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
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[800],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Save Settings',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}