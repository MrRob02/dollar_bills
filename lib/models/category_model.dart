class CategoryModel {
  final String id;
  final String name;
  final int iconCodePoint;
  final String colorHex;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.iconCodePoint,
    required this.colorHex,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'iconCodePoint': iconCodePoint,
        'colorHex': colorHex,
      };

  factory CategoryModel.fromMap(Map<dynamic, dynamic> map) {
    return CategoryModel(
      id: map['id'] as String,
      name: map['name'] as String,
      iconCodePoint: map['iconCodePoint'] as int? ?? 0xe043,
      colorHex: map['colorHex'] as String? ?? 'FF3EB489',
    );
  }

  CategoryModel copyWith({
    String? name,
    int? iconCodePoint,
    String? colorHex,
  }) {
    return CategoryModel(
      id: id,
      name: name ?? this.name,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      colorHex: colorHex ?? this.colorHex,
    );
  }
}
