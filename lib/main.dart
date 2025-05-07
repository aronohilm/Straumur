import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:fluttertoast/fluttertoast.dart';

void main() => runApp(const PaymentApp());

class PaymentApp extends StatelessWidget {
  const PaymentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'POS Payment',
      debugShowCheckedModeBanner: false,
      home: const PaymentScreen(),
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
  String _response = '';
  bool _isLoading = false;
  int _saleCounter = 1;
  late Timer _timer;
  late String _currentTime;

  final String _apiKey = "YOUR_API_KEY_HERE";
  final String _url = "https://terminal-api-test.adyen.com/sync";
  final String _poiId = "S1F2-000158242574825";

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
  }

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
      _amount += digit;
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

      final responseJson = jsonDecode(response.body);
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
      });

      await _incrementCounter();
      _showToast('Sent to POS');
    } catch (e) {
      setState(() {
        _response = 'Villa: $e';
        _isLoading = false;
      });
      _showToast('Villa við sendingu');
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
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[800],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 20),
          ),
          onPressed: onTap,
          child: Text(label, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.blue[800],
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.local_pizza, color: Colors.white, size: 32),
                  Text(_currentTime, style: const TextStyle(color: Colors.white)),
                  Row(children: const [
                    Icon(Icons.wifi, color: Colors.lightGreenAccent, size: 12),
                    SizedBox(width: 4),
                    Text('straumur', style: TextStyle(color: Colors.lightGreenAccent)),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                height: 100, // Make the text field bigger
                child: TextField(
                  readOnly: true,
                  controller: TextEditingController(
                    text: _amount.isEmpty
                        ? ''
                        : '${_formatAmount(_amount)} ISK',
                  ),
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 36),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    for (var row in [
                      ['1', '2', '3'],
                      ['4', '5', '6'],
                      ['7', '8', '9'],
                      [' ', '0', '<']
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
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                height: 80,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[800],
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(_isLoading ? 'Sending...' : 'SENDA Í POSA', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Add this method to your _PaymentScreenState class:
String _formatAmount(String amount) {
  if (amount.isEmpty) return '';
  final number = int.tryParse(amount.replaceAll('.', '')) ?? 0;
  return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
}