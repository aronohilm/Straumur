class Product {
  final String id;
  final String name;
  final double price;
  final String category;
  int position;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    this.position = -1,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'category': category,
    'position': position,
  };

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      price: (json['price'] as num).toDouble(),
      category: json['category'],
      position: json['position'] ?? -1,
    );
  }
} 