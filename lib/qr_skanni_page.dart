import 'package:flutter/material.dart';

class QRSkanniPage extends StatefulWidget {
  const QRSkanniPage({super.key});

  @override
  State<QRSkanniPage> createState() => _QRSkanniPageState();
}

class _QRSkanniPageState extends State<QRSkanniPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR-Skanni', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF002244),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.qr_code_scanner,
              size: 80,
              color: Color(0xFF002244),
            ),
            const SizedBox(height: 20),
            Text(
              'QR-Skanni',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF002244),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'QR Scanner functionality coming soon',
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