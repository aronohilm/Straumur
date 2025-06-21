class Order {
  final String id;
  final Map<String, int> items; // Product ID -> quantity
  final double totalAmount;
  final DateTime timestamp;
  final bool successful;

  Order({
    required this.id,
    required this.items,
    required this.totalAmount,
    required this.timestamp,
    required this.successful,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'items': items,
    'totalAmount': totalAmount,
    'timestamp': timestamp.toIso8601String(),
    'successful': successful,
  };

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      items: Map<String, int>.from(json['items']),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
      successful: json['successful'],
    );
  }
} 