import 'package:flutter/material.dart';

class EndurgreidslaPage extends StatefulWidget {
  const EndurgreidslaPage({super.key});

  @override
  State<EndurgreidslaPage> createState() => _EndurgreidslaPageState();
}

class _EndurgreidslaPageState extends State<EndurgreidslaPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Endurgreiðsla', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF002244),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.money_off,
              size: 80,
              color: Color(0xFF002244),
            ),
            const SizedBox(height: 20),
            Text(
              'Endurgreiðsla',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF002244),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Refund functionality coming soon',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}