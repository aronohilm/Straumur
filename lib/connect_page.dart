import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ConnectPage extends StatefulWidget {
  const ConnectPage({super.key});

  @override
  State<ConnectPage> createState() => _ConnectPageState();
}

class _ConnectPageState extends State<ConnectPage> {
  final TextEditingController _lastDigitsController = TextEditingController();
  final String _poiIdBase = "S1F2-000000225110";
  String _savedPoiId = '';

  @override
  void initState() {
    super.initState();
    _loadSavedPoiId();
  }

  Future<void> _loadSavedPoiId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedPoiId = prefs.getString('selected_terminal') ?? '';
    });
  }

  Future<void> _savePoiId() async {
    if (_lastDigitsController.text.isEmpty) {
      Fluttertoast.showToast(msg: "Please enter the last digits of the terminal ID.");
      return;
    }
    // As requested: "add to this string 'S1F2L-000158225110'".
    // This will append the digits to the base string.
    final newPoiId = _poiIdBase + _lastDigitsController.text;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_terminal', newPoiId);
    setState(() {
      _savedPoiId = newPoiId;
    });
    _lastDigitsController.clear();
    FocusScope.of(context).unfocus(); // Dismiss keyboard
    Fluttertoast.showToast(msg: "Terminal ID saved!");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect to Terminal'),
        backgroundColor: const Color(0xFF002B5B),
      ),
      backgroundColor: const Color(0xFF002244),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Enter last digits of the POS terminal to be added to:\n"$_poiIdBase"',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _lastDigitsController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 24),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF0A3A6A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                hintText: 'e.g., 123',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 60,
              child: ElevatedButton(
                onPressed: _savePoiId,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('SAVE', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'Currently Saved Terminal ID:',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0A3A6A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _savedPoiId.isEmpty ? 'Not set' : _savedPoiId,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 