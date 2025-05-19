import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

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
            icon: const Icon(Icons.refresh),
            onPressed: _loadLogs,
            tooltip: 'Refresh',
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
        title: Text(
          'Færsla: ${log['sale_id']}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
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
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Loka'),
          ),
        ],
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