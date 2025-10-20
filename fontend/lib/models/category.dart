class Category {
  final int id;
  final String name;
  final String? description;
  final DateTime createdAt;

  Category({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? json['Id'] ?? 0,
      name: json['name'] ?? json['Name'] ?? '',
      description: json['description'] ?? json['Description'],
      createdAt: json['createdAt'] != null || json['CreatedAt'] != null
          ? DateTime.parse(json['createdAt'] ?? json['CreatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() => 'Category(id: $id, name: $name)';
}
