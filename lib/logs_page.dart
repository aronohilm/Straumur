import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class LogsPage extends StatefulWidget {
  const LogsPage({super.key});
  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/adyen_log.txt');
    if (await file.exists()) {
      final lines = await file.readAsLines();
      setState(() {
        _logs = lines.reversed.toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Transaction Logs')),
      body: ListView.builder(
        itemCount: _logs.length,
        itemBuilder: (context, index) => ListTile(
          title: Text(_logs[index]),
        ),
      ),
    );
  }
}