class MenuItem {
  final int? id;
  final String name;
  final String category;
  final double price;
  final String? description;
  final bool isAvailable;
  final String? imagePath;

  const MenuItem({
    this.id,
    required this.name,
    required this.category,
    required this.price,
    this.description,
    this.isAvailable = true,
    this.imagePath,
  });

  MenuItem copyWith({
    int? id,
    String? name,
    String? category,
    double? price,
    String? description,
    bool? isAvailable,
    String? imagePath,
    bool clearImage = false,
  }) {
    return MenuItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      description: description ?? this.description,
      isAvailable: isAvailable ?? this.isAvailable,
      imagePath: clearImage ? null : (imagePath ?? this.imagePath),
    );
  }

  factory MenuItem.fromMap(Map<String, dynamic> map) => MenuItem(
        id: map['id'] as int?,
        name: map['name'] as String,
        category: map['category'] as String,
        price: (map['price'] as num).toDouble(),
        description: map['description'] as String?,
        isAvailable: (map['is_available'] as int) == 1,
        imagePath: map['image_path'] as String?,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'category': category,
        'price': price,
        'description': description,
        'is_available': isAvailable ? 1 : 0,
        'image_path': imagePath,
      };
}
