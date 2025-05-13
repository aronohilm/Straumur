import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'logs_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'login_page.dart';
import 'settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const PaymentApp());

class PaymentApp extends StatelessWidget {
  const PaymentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'POS Payment',
      debugShowCheckedModeBanner: false,
      home: const PaymentScreen(), // Changed from LoginPage to PaymentScreen
    );
  }
}

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _amount = '';
  String _transactionStatus = ''; 
  bool _isLoading = false;
  int _saleCounter = 1;
  late Timer _timer;
  late String _currentTime;
  String _response = ''; // Add this line to define the _response variable
  
  final String _apiKey = "AQEqhmfxL43JaxFCw0m/n3Q5qf3Ve59fDIZHTXfy5UT9AM9RlDqYku8lh1U2EMFdWw2+5HzctViMSCJMYAc=-iql6F+AYb1jkHn3zzDBcXZZvYzXFr9wd1iCR9y2JDU0=-i1i{=<;wFH*jLc94NQe";
  final String _url = "https://terminal-api-test.adyen.com/sync";
  final String _poiId = "S1F2-000158242574825";
  String? _selectedTerminal;

  @override
  void initState() {
    super.initState();
    _loadCounter();
    _currentTime = _getTimeString();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _currentTime = _getTimeString();
      });
    });
    _loadSelectedTerminal();
  }

  Future<void> _loadSelectedTerminal() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedTerminal = prefs.getString('selected_terminal');
    });
  }
  // Use _selectedTerminal in your payment logic

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _getTimeString() {
    final now = DateTime.now();
    return "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
  }

  Future<void> _loadCounter() async {
    final file = await _getCounterFile();
    if (await file.exists()) {
      final content = await file.readAsString();
      setState(() => _saleCounter = int.tryParse(content.trim()) ?? 1);
    }
  }

  Future<void> _incrementCounter() async {
    final file = await _getCounterFile();
    _saleCounter++;
    await file.writeAsString(_saleCounter.toString());
  }

  Future<File> _getCounterFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/saleid_counter.txt');
  }

  Future<File> _getLogFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/adyen_log.txt');
  }

  void _appendDigit(String digit) {
    setState(() {
      // If the digit is "000", add three zeros
      if (digit == "000") {
        _amount += "000";
      } else {
        _amount += digit;
      }
      _transactionStatus = ''; // Clear status when entering a new amount
    });
  }

  void _backspace() {
    if (_amount.isNotEmpty) {
      setState(() => _amount = _amount.substring(0, _amount.length - 1));
    }
  }

  Future<void> _sendPayment() async {
    if (_amount.isEmpty) {
      _showToast('Sláðu inn upphæð');
      return;
    }

    double? amount;
    try {
      amount = double.parse(_amount);
      if (amount <= 0) {
        _showToast('Upphæð verður að vera stærri en 0');
        return;
      }
    } catch (_) {
      _showToast('Ógild upphæð');
      return;
    }

    setState(() {
      _isLoading = true;
      _response = 'Sending...';
    });

    final now = DateTime.now().toUtc();
    final saleId = 'FlutterTest${_saleCounter.toString().padLeft(3, '0')}';
    final serviceId = '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    final transactionId = 'TX${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    final timestamp = now.toIso8601String() + 'Z';

    final payload = {
      "SaleToPOIRequest": {
        "MessageHeader": {
          "ProtocolVersion": "3.0",
          "MessageClass": "Service",
          "MessageCategory": "Payment",
          "MessageType": "Request",
          "SaleID": saleId,
          "ServiceID": serviceId,
          "POIID": _poiId
        },
        "PaymentRequest": {
          "SaleData": {
            "SaleTransactionID": {
              "TransactionID": transactionId,
              "TimeStamp": timestamp
            }
          },
          "PaymentTransaction": {
            "AmountsReq": {
              "Currency": "EUR",
              "RequestedAmount": amount
            }
          }
        }
      }
    };

    try {
      final response = await http.post(
        Uri.parse(_url),
        headers: {
          'Content-Type': 'application/json',
          'X-API-Key': _apiKey,
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode != 200) {
        setState(() {
          _response = 'Error: ${response.statusCode}\n${response.body}';
          _isLoading = false;
          _amount = ''; // Clear the amount field on error
          _transactionStatus = 'Declined'; // Set status to declined on HTTP error
        });
        _showToast('Payment failed: ${response.statusCode}');
        return;
      }

      final responseJson = jsonDecode(response.body);
      
      // Determine transaction status
      String transactionStatus = 'Unknown';
      if (responseJson['SaleToPOIResponse'] != null && 
          responseJson['SaleToPOIResponse']['PaymentResponse'] != null &&
          responseJson['SaleToPOIResponse']['PaymentResponse']['Response'] != null) {
        
        final responseResult = responseJson['SaleToPOIResponse']['PaymentResponse']['Response']['Result'];
        transactionStatus = responseResult == 'Success' ? 'Approved' : 'Declined';
      }
      
      final logEntry = {
        'timestamp': now.toIso8601String(),
        'sale_id': saleId,
        'amount': amount,
        'status': response.statusCode,
        'response': responseJson,
      };

      final logFile = await _getLogFile();
      await logFile.writeAsString('${jsonEncode(logEntry)}\n', mode: FileMode.append);

      setState(() {
        _response = const JsonEncoder.withIndent('  ').convert(responseJson);
        _isLoading = false;
        _amount = ''; // Clear the amount field after successful response
        _transactionStatus = transactionStatus; // Set the transaction status
      });

      await _incrementCounter();
      _showToast('Sent to POS');
    } catch (e) {
      setState(() {
        _response = 'Error: $e';
        _isLoading = false;
        _amount = ''; // Clear the amount field on exception
        _transactionStatus = 'Declined'; // Set status to declined on exception
      });
      _showToast('Network error: $e');
    }
  }

  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.black87,
      textColor: Colors.white,
    );
  }

  Widget _buildKeypadButton(String label, {VoidCallback? onTap}) {
    Color buttonColor = const Color(0xFF002244);
    Color textColor = Colors.white;
    
    // Make the backspace button yellow
    if (label == '<') {
      buttonColor = const Color(0xFF002244);
      textColor = Colors.amber;
    }
    
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(6.0), // Reduced from 8.0 to 6.0
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 25), // Reduced from 30 to 25
          ),
          onPressed: onTap,
          child: Text(label, style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: textColor)), // Reduced from 32 to 30
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF002244), // Dark blue background
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: const Color(0xFF002244), // Dark blue header
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Replace merchant store name with "MERCHANT" in all caps
                  const Text(
                    "MERCHANT",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(_currentTime, style: const TextStyle(color: Colors.white, fontSize: 22)),
                  Row(
                    children: [
                      const Icon(Icons.wifi, color: Colors.lightGreenAccent, size: 12),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const SettingsPage()),
                          );
                        },
                        child: const Text(
                          'straumur',
                          style: TextStyle(color: Colors.lightGreenAccent, decoration: TextDecoration.underline, fontSize: 18),
                        ),
                      ),
                    ], 
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            // Reduce the height of the amount field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF0A3A6A), // Added ligher blue background
                  border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  readOnly: true,
                  controller: TextEditingController(
                    text: _amount.isEmpty
                        ? ''
                        : '${_formatAmount(_amount)} EUR',
                  ),
                  textAlign: TextAlign.left,
                  style: const TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            // Reduce vertical padding for status message
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20), // Reduced from 20 to 10
              child: _transactionStatus.isNotEmpty
                ? Text(
                    _transactionStatus,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: _transactionStatus == 'Approved' ? Colors.green : Colors.red,
                    ),
                  )
                : const SizedBox(height: 80), // Reduced from 50 to 20
            ),
            
            // Remove the Spacer completely
            // const Spacer(flex: 1), <- Remove this line
            
            // Keyboard section with reduced padding
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  for (var row in [
                    ['1', '2', '3'],
                    ['4', '5', '6'],
                    ['7', '8', '9'],
                    ['000', '0', '<']
                  ])
                    Row(
                      children: row.map((label) {
                        return _buildKeypadButton(label, onTap: () {
                          if (label == '<') {
                            _backspace();
                          } else {
                            _appendDigit(label);
                          }
                        });
                      }).toList(),
                    ),
                ],
              ),
            ),
            
            // Reduce height between keypad and send button
            const SizedBox(height: 60), // Reduced from 20 to 10
            
            // Reduce the height of the send button
            Padding(
              padding: const EdgeInsets.all(10), // Reduced from 16 to 10
              child: SizedBox(
                width: double.infinity,
                height: 70, // Reduced from 80 to 70
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Color.fromARGB(255, 102, 4, 222))
                      : const Text(
                          'SENDA Í POSA',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF002244),
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Update the format method to match the new style
  String _formatAmount(String amount) {
    if (amount.isEmpty) return '0';
    final number = int.tryParse(amount) ?? 0;
    
    // Format with dot as thousands separator
    final formattedNumber = number.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
    
    return formattedNumber;
  }
}