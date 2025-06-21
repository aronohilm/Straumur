import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'models/order.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  List<Order> _orders = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadOrders();
  }
  
  Future<File> _getOrdersFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/orders.json');
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final file = await _getOrdersFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          final List<dynamic> ordersJson = jsonDecode(content);
          _orders = ordersJson.map((json) => Order.fromJson(json)).toList();
        } else {
          _orders = [];
        }
      } else {
        _orders = [];
      }
    } catch (e) {
      print("Error loading orders: $e");
      _orders = [];
    }
    setState(() {
      _isLoading = false;
    });
  }
  
  Map<String, int> _getTopSellingItems() {
    Map<String, int> itemCounts = {};
    
    for (var order in _orders) {
      if (order.successful) {
        order.items.forEach((id, quantity) {
          itemCounts[id] = (itemCounts[id] ?? 0) + quantity;
        });
      }
    }
    
    var sortedEntries = itemCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    Map<String, int> topItems = {};
    for (var i = 0; i < sortedEntries.length && i < 5; i++) {
      topItems[sortedEntries[i].key] = sortedEntries[i].value;
    }
    
    return topItems;
  }
  
  double _getTotalRevenue() {
    return _orders
        .where((order) => order.successful)
        .fold(0, (sum, order) => sum + order.totalAmount);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF002B5B),
      appBar: AppBar(
        title: const Text(
          "Tölfræði",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF002B5B),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Yfirlit",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatCard(
                          "Heildarupphæð",
                          "${_getTotalRevenue().toStringAsFixed(2)} kr",
                        ),
                        _buildStatCard(
                          "Fjöldi pantana",
                          "${_orders.where((o) => o.successful).length}",
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Vinsælustu vörur",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _orders.isEmpty
                          ? const Center(
                              child: Text(
                                "Engar pantanir enn",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _getTopSellingItems().length,
                              itemBuilder: (context, index) {
                                final entry = _getTopSellingItems().entries.elementAt(index);
                                return ListTile(
                                  leading: Container(
                                    width: 40,
                                    height: 40,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD6FF94),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      "${index + 1}",
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF002B5B),
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    entry.key,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF002B5B),
                                    ),
                                  ),
                                  trailing: Text(
                                    "${entry.value} stk",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Color(0xFF002B5B),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
  
  Widget _buildStatCard(String title, String value) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF002B5B),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF002B5B),
          ),
        ),
      ],
    );
  }
} 