import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class FaerslulistiPage extends StatefulWidget {
  const FaerslulistiPage({super.key});
  @override
  State<FaerslulistiPage> createState() => _FaerslulistiPageState();
}

class _FaerslulistiPageState extends State<FaerslulistiPage> {
  List<Map<String, dynamic>> _parsedLogs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/adyen_log.txt');
      if (await file.exists()) {
        final lines = await file.readAsLines();
        final parsedLogs = <Map<String, dynamic>>[];
        
        for (final line in lines) {
          try {
            final logEntry = jsonDecode(line) as Map<String, dynamic>;
            
            // Extract response status
            String status = 'Unknown';
            String responseCode = 'N/A';
            String saleId = logEntry['sale_id'] ?? 'Unknown';
            
            if (logEntry['response'] != null && 
                logEntry['response']['SaleToPOIResponse'] != null &&
                logEntry['response']['SaleToPOIResponse']['PaymentResponse'] != null &&
                logEntry['response']['SaleToPOIResponse']['PaymentResponse']['Response'] != null) {
              
              final response = logEntry['response']['SaleToPOIResponse']['PaymentResponse']['Response'];
              responseCode = response['Result'] ?? 'N/A';
              
              if (responseCode == 'Success') {
                status = 'Approved';
              } else {
                status = 'Declined';
              }
            }
            
            parsedLogs.add({
              'timestamp': logEntry['timestamp'] ?? '',
              'amount': logEntry['amount'] ?? 0.0,
              'status': status,
              'responseCode': responseCode,
              'sale_id': saleId,
              'fullData': logEntry,
            });
          } catch (e) {
            // Skip invalid entries
            print('Error parsing log entry: $e');
          }
        }
        
        setState(() {
          _parsedLogs = parsedLogs.reversed.toList();
          _isLoading = false;
        });
      } else {
        // If no log file exists, use mock data
        _loadMockData();
      }
    } catch (e) {
      print('Error loading logs: $e');
      // Fall back to mock data if there's an error
      _loadMockData();
    }
  }

  void _loadMockData() {
    final now = DateTime.now();
    final parsedLogs = <Map<String, dynamic>>[];
    
    for (int i = 0; i < 10; i++) {
      final transactionTime = now.subtract(Duration(days: i, hours: i * 2));
      final amount = (100 + (i * 25)).toDouble();
      final status = i % 3 == 0 ? 'Declined' : 'Approved';
      final saleId = 'MOCK${(1000 + i).toString()}';
      
      final mockData = {
        'timestamp': transactionTime.toIso8601String(),
        'amount': amount,
        'status': status,
        'responseCode': status == 'Approved' ? 'Success' : 'Failure',
        'sale_id': saleId,
        'fullData': {
          'timestamp': transactionTime.toIso8601String(),
          'sale_id': saleId,
          'amount': amount,
          'status': 200,
          'response': {
            'SaleToPOIResponse': {
              'PaymentResponse': {
                'Response': {
                  'Result': status == 'Approved' ? 'Success' : 'Failure'
                },
                'PaymentResult': {
                  'AmountsResp': {
                    'Currency': 'EUR',
                    'AuthorizedAmount': amount
                  }
                }
              }
            }
          }
        }
      };
      
      parsedLogs.add(mockData);
    }
    
    setState(() {
      _parsedLogs = parsedLogs;
      _isLoading = false;
    });
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      return DateFormat('dd.MM.yyyy - HH:mm').format(dateTime);
    } catch (e) {
      return timestamp;
    }
  }

  String _formatAmount(dynamic amount) {
    if (amount is num) {
      return '€${amount.toStringAsFixed(2)}';
    }
    return '€0.00';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Færslulisti',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF002244),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'Prenta heildarlista',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Prenta heildarlista'),
                  content: const Text('Viltu prenta heildarlistann?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Hætta við'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        // Add your print logic here
                        Navigator.pop(context);
                      },
                      child: const Text('Prenta'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _parsedLogs.isEmpty
              ? const Center(child: Text('Engar færslur fundust'))
              : ListView.builder(
                  itemCount: _parsedLogs.length,
                  itemBuilder: (context, index) {
                    final log = _parsedLogs[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 2,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: log['status'] == 'Approved' 
                              ? Colors.green 
                              : Colors.red,
                          child: Icon(
                            log['status'] == 'Approved' 
                                ? Icons.check 
                                : Icons.close,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          'Færsla: ${log['sale_id']}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_formatTimestamp(log['timestamp'])),
                            Text(_formatAmount(log['amount'])),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          _showTransactionDetails(context, log);
                        },
                      ),
                    );
                  },
                ),
    );
  }

  void _showTransactionDetails(BuildContext context, Map<String, dynamic> log) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: const EdgeInsets.only(left: 24, right: 24, bottom: 24, top: 20),
        // Remove the title and add a close button in the top-left
        title: null,
        // Add a close button (X) in the top left
        titlePadding: EdgeInsets.zero,
        // Add the X button to the top left
        actions: null, // Remove default actions
        content: Stack(
          clipBehavior: Clip.none,
          children: [
            // Close button (X) at top left
            Positioned(
              left: -10,
              top: -10,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
            // Main content
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title now inside content
                Center(
                  child: Text(
                    'Færsla: ${log['sale_id']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildDetailRow('Staða:', log['status'], 
                    color: log['status'] == 'Approved' ? Colors.green : Colors.red),
                _buildDetailRow('Dagsetning:', _formatTimestamp(log['timestamp'])),
                _buildDetailRow('Upphæð:', _formatAmount(log['amount'])),
                
                const Divider(),
                const Text(
                  'Nánar:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                
                // Display the full JSON response in a formatted way
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    const JsonEncoder.withIndent('  ').convert(log['fullData']),
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
                
                // Bottom buttons
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Only show refund button for approved transactions
                    if (log['status'] == 'Approved')
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context); // Close the details dialog
                            _showRefundConfirmation(context, log);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Endurgreiða'),
                        ),
                      ),
                    if (log['status'] == 'Approved')
                      const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // Show email receipt dialog
                          _showSendReceiptDialog(context, log);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Senda Kvittun'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Add this new method to show the send receipt dialog
  void _showSendReceiptDialog(BuildContext context, Map<String, dynamic> log) {
    final TextEditingController emailController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Senda kvittun'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Sláðu inn netfang til að senda kvittun:'),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Netfang',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hætta við'),
          ),
          ElevatedButton(
            onPressed: () {
              // Validate email
              final email = emailController.text.trim();
              if (email.isEmpty || !email.contains('@')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ógilt netfang')),
                );
                return;
              }
              
              // Close the dialog
              Navigator.pop(context);
              
              // Show confirmation
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Kvittun send á $email')),
              );
              
              // Here you would implement the actual email sending logic
              // This is just a placeholder
            },
            child: const Text('Senda'),
          ),
        ],
      ),
    );
  }

  // Add this new method to show a confirmation dialog before refunding
  void _showRefundConfirmation(BuildContext context, Map<String, dynamic> log) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Staðfesta endurgreiðslu'),
        content: Text(
          'Ertu viss um að þú viljir endurgreiða færslu ${log['sale_id']} að upphæð ${_formatAmount(log['amount'])}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hætta við'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processRefund(log);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Endurgreiða'),
          ),
        ],
      ),
    );
  }

  // Add this method to process the refund
  Future<void> _processRefund(Map<String, dynamic> log) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get the stored API settings
      final prefs = await SharedPreferences.getInstance();
      final endpoint = prefs.getString('endpoint') ?? 'https://terminal-api-test.adyen.com/sync';
      final apiKey = prefs.getString('api_key') ?? '';
      final poiId = prefs.getString('selected_terminal') ?? '';

      if (apiKey.isEmpty || poiId.isEmpty) {
        _showToast('API key or terminal not configured');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Extract transaction ID and timestamp from the log
      String transactionId = '';
      String timestamp = '';
      
      // Try to extract the transaction ID from the fullData
      if (log['fullData'] != null && 
          log['fullData']['response'] != null && 
          log['fullData']['response']['SaleToPOIResponse'] != null &&
          log['fullData']['response']['SaleToPOIResponse']['PaymentResponse'] != null &&
          log['fullData']['response']['SaleToPOIResponse']['PaymentResponse']['POIData'] != null &&
          log['fullData']['response']['SaleToPOIResponse']['PaymentResponse']['POIData']['POITransactionID'] != null) {
        
        final poiData = log['fullData']['response']['SaleToPOIResponse']['PaymentResponse']['POIData'];
        transactionId = poiData['POITransactionID']['TransactionID'] ?? '';
        timestamp = poiData['POITransactionID']['TimeStamp'] ?? '';
      }

      if (transactionId.isEmpty) {
        _showToast('Transaction ID not found in log data');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Generate unique service ID
      final now = DateTime.now();
      final serviceId = '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';

      // Create the reversal request payload
      final Map<String, dynamic> requestPayload = {
        "SaleToPOIRequest": {
          "MessageHeader": {
            "ProtocolVersion": "3.0",
            "MessageClass": "Service",
            "MessageCategory": "Reversal",
            "MessageType": "Request",
            "SaleID": "POSSystemID12345",
            "ServiceID": serviceId,
            "POIID": poiId
          },
          "ReversalRequest": {
            "OriginalPOITransaction": {
              "POITransactionID": {
                "TransactionID": transactionId,
                "TimeStamp": timestamp
              }
            },
            "ReversalReason": "MerchantCancel"
          }
        }
      };

      // Make the API request
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'X-API-Key': apiKey,
        },
        body: jsonEncode(requestPayload),
      );

      // Log the response
      final dir = await getApplicationDocumentsDirectory();
      final logFile = File('${dir.path}/adyen_log.txt');
      
      final logEntry = {
        'timestamp': DateTime.now().toIso8601String(),
        'sale_id': 'REFUND-${log['sale_id']}',
        'amount': log['amount'],
        'status': response.statusCode,
        'request': requestPayload,
        'response': response.statusCode == 200 ? jsonDecode(response.body) : {'error': response.body},
      };
      
      await logFile.writeAsString('${jsonEncode(logEntry)}\n', mode: FileMode.append);

      // Process the response
      if (response.statusCode == 200) {
        final responseJson = jsonDecode(response.body);
        
        // Determine if refund was successful
        String refundStatus = 'Unknown';
        if (responseJson['SaleToPOIResponse'] != null && 
            responseJson['SaleToPOIResponse']['ReversalResponse'] != null &&
            responseJson['SaleToPOIResponse']['ReversalResponse']['Response'] != null) {
          
          final result = responseJson['SaleToPOIResponse']['ReversalResponse']['Response']['Result'];
          refundStatus = result == 'Success' ? 'Approved' : 'Declined';
        }
        
        _showToast('Endurgreiðsla ${refundStatus == 'Approved' ? 'tókst' : 'mistókst'}');
        
        // Reload the transaction list to show the updated status
        _loadLogs();
      } else {
        _showToast('Villa: ${response.statusCode} - ${response.reasonPhrase}');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      _showToast('Villa: ${e.toString()}');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Add this helper method to show toast messages
  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }
  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: color),
            ),
          ),
        ],
      ),
    );
  }
}