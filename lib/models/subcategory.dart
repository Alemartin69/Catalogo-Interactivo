class Subcategory {
  final String id;
  final String categoryId;
  String name;
  String? description;
  int sortOrder;
  final DateTime createdAt;

  Subcategory({
    required this.id,
    required this.categoryId,
    required this.name,
    this.description,
    this.sortOrder = 0,
    required this.createdAt,
  });

  factory Subcategory.fromMap(Map<String, dynamic> map) => Subcategory(
        id: map['id'] as String,
        categoryId: map['category_id'] as String,
        name: map['name'] as String,
        description: map['description'] as String?,
        sortOrder: (map['sort_order'] as int?) ?? 0,
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'category_id': categoryId,
        'name': name,
        'description': description,
        'sort_order': sortOrder,
        'created_at': createdAt.toIso8601String(),
      };

  Map<String, dynamic> toJson() => toMap();

  factory Subcategory.fromJson(Map<String, dynamic> json) =>
      Subcategory.fromMap(json);
}
