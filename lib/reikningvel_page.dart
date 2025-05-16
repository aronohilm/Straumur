import 'package:flutter/material.dart';

class ReikningvelPage extends StatefulWidget {
  const ReikningvelPage({super.key});

  @override
  State<ReikningvelPage> createState() => _ReikningvelPageState();
}

class _ReikningvelPageState extends State<ReikningvelPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reikningvél', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF002244),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.calculate,
              size: 80,
              color: Color(0xFF002244),
            ),
            const SizedBox(height: 20),
            Text(
              'Reikningvél',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF002244),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Calculator functionality coming soon',
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