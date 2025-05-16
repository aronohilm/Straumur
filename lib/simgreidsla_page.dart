import 'package:flutter/material.dart';

class SimgreidslaPage extends StatefulWidget {
  const SimgreidslaPage({super.key});

  @override
  State<SimgreidslaPage> createState() => _SimgreidslaPageState();
}

class _SimgreidslaPageState extends State<SimgreidslaPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Símgreiðsla', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF002244),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.phone_android,
              size: 80,
              color: Color(0xFF002244),
            ),
            const SizedBox(height: 20),
            Text(
              'Símgreiðsla',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF002244),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Phone payment functionality coming soon',
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