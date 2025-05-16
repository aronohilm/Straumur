import 'package:flutter/material.dart';

class SjoppanPage extends StatefulWidget {
  const SjoppanPage({super.key});

  @override
  State<SjoppanPage> createState() => _SjoppanPageState();
}

class _SjoppanPageState extends State<SjoppanPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sjoppan', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF002244),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.shopping_cart,
              size: 80,
              color: Color(0xFF002244),
            ),
            const SizedBox(height: 20),
            Text(
              'Sjoppan',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF002244),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Shop functionality coming soon',
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