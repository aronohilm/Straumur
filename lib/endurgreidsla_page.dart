import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EndurgreidslaPage extends StatefulWidget {
  const EndurgreidslaPage({super.key});

  @override
  State<EndurgreidslaPage> createState() => _EndurgreidslaPageState();
}

class _EndurgreidslaPageState extends State<EndurgreidslaPage> {
  String _amount = '';
  String _transactionStatus = '';
  bool _isLoading = false;
  int _refundCounter = 1;
  late Timer _timer;
  late String _currentTime;
  String _response = '';
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
      setState(() => _refundCounter = int.tryParse(content.trim()) ?? 1);
    }
  }

  Future<void> _incrementCounter() async {
    final file = await _getCounterFile();
    _refundCounter++;
    await file.writeAsString(_refundCounter.toString());
  }

  Future<File> _getCounterFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/refund_counter.txt');
  }

  Future<File> _getLogFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/adyen_refund_log.txt');
  }

  void _appendDigit(String digit) {
    setState(() {
      if (digit == "000") {
        _amount += "000";
      } else {
        _amount += digit;
      }
      _transactionStatus = '';
    });
  }

  void _backspace() {
    if (_amount.isNotEmpty) {
      setState(() => _amount = _amount.substring(0, _amount.length - 1));
    }
  }

  Future<void> _sendRefund() async {
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

    final prefs = await SharedPreferences.getInstance();
    final endpoint = prefs.getString('endpoint') ?? _url;
    final apiKey = prefs.getString('api_key') ?? _apiKey;
    final poiId = prefs.getString('selected_terminal') ?? _poiId;

    final now = DateTime.now().toUtc();
    final saleId = 'Refund${_refundCounter.toString().padLeft(3, '0')}';
    final serviceId = '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    final transactionId = 'RF${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
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
          "POIID": poiId
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
          },
          "PaymentData": {
            "PaymentType": "Refund"
          }
        }
      }
    };

    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'X-API-Key': apiKey,
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode != 200) {
        setState(() {
          _response = 'Error: ${response.statusCode}\n${response.body}';
          _isLoading = false;
          _amount = '';
          _transactionStatus = 'Declined';
        });
        _showToast('Refund failed: ${response.statusCode}');
        return;
      }

      final responseJson = jsonDecode(response.body);

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
        _amount = '';
        _transactionStatus = transactionStatus;
      });

      await _incrementCounter();
      _showToast('Refund sent to POS');
    } catch (e) {
      setState(() {
        _response = 'Error: $e';
        _isLoading = false;
        _amount = '';
        _transactionStatus = 'Declined';
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

  @override
  Widget build(BuildContext context) {
    // Get screen size for responsive layout
    final screenSize = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: const Color(0xFF002244),
      appBar: AppBar(
        backgroundColor: const Color(0xFF002244),
        elevation: 0,
        title: const Text(
          'Endurgreiðsla',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 36),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header - fixed at top
            const SizedBox(height: 10),
            
            // Input field - takes a percentage of available space
            Padding(
              padding: EdgeInsets.all(screenSize.width * 0.04),
              child: Container(
                height: screenSize.height * 0.12,
                decoration: BoxDecoration(
                  color: const Color(0xFF0A3A6A),
                  border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  readOnly: true,
                  controller: TextEditingController(
                    text: _amount.isEmpty ? '' : '${(_amount)} EUR',
                  ),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: screenSize.width * 0.08,
                    color: Colors.white,
                    fontWeight: FontWeight.bold
                  ),
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            
            // Status message
            SizedBox(
              height: screenSize.height * 0.06,
              child: _transactionStatus.isNotEmpty
                ? Text(
                    _transactionStatus,
                    style: TextStyle(
                      fontSize: screenSize.width * 0.06,
                      fontWeight: FontWeight.bold,
                      color: _transactionStatus == 'Approved' ? Colors.green : Colors.red,
                    ),
                  )
                : const SizedBox(),
            ),
            
            // Keypad - takes most of the remaining space
            Expanded(
              flex: 5,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenSize.width * 0.03,
                  vertical: screenSize.height * 0.01,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (var row in [
                      ['1', '2', '3'],
                      ['4', '5', '6'],
                      ['7', '8', '9'],
                      ['000', '0', '<']
                    ])
                      Expanded(
                        child: Row(
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
                      ),
                  ],
                ),
              ),
            ),
            
            // Send button - fixed at bottom
            Padding(
              padding: EdgeInsets.all(screenSize.width * 0.03),
              child: SizedBox(
                width: double.infinity,
                height: screenSize.height * 0.08,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF002244),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _isLoading ? null : _sendRefund,
                  child: _isLoading
                    ? const CircularProgressIndicator()
                    : Text(
                        "Endurgreiða",
                        style: TextStyle(
                          fontSize: screenSize.width * 0.06,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
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

  // Update the keypad button to be responsive
  Widget _buildKeypadButton(String label, {VoidCallback? onTap}) {
    Color buttonColor = const Color(0xFF002244);
    Color textColor = Colors.white;
    
    if (label == '<') {
      buttonColor = const Color(0xFF002244);
      textColor = Colors.amber;
    }
    
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: EdgeInsets.zero,
          ),
          onPressed: onTap,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                label, 
                style: TextStyle(
                  fontSize: 30, 
                  fontWeight: FontWeight.bold, 
                  color: textColor
                )
              ),
            ),
          ),
        ),
      ),
    );
  }
}