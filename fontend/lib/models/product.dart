class Product {
  final int id;
  final String name;
  final double price;
  final String? image;
  final String? description;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    this.image,
    this.description,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // Support both camelCase (API default) and PascalCase (fallback)
    int parseId(dynamic v) => v is int ? v : int.tryParse(v.toString()) ?? 0;
    double parsePrice(dynamic v) =>
        v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '0') ?? 0;

    return Product(
      id: parseId(json['id'] ?? json['Id']),
      name: (json['name'] ?? json['Name'] ?? '').toString(),
      price: parsePrice(json['price'] ?? json['Price']),
      image: (json['image'] ?? json['Image'])?.toString(),
      description: (json['description'] ?? json['Description'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'image': image,
      'description': description,
    };
  }
}
