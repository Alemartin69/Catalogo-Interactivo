class Category {
  final String id;
  String name;
  String? description;
  String? icon;
  int sortOrder;
  final DateTime createdAt;

  Category({
    required this.id,
    required this.name,
    this.description,
    this.icon,
    this.sortOrder = 0,
    required this.createdAt,
  });

  factory Category.fromMap(Map<String, dynamic> map) => Category(
        id: map['id'] as String,
        name: map['name'] as String,
        description: map['description'] as String?,
        icon: map['icon'] as String?,
        sortOrder: (map['sort_order'] as int?) ?? 0,
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'icon': icon,
        'sort_order': sortOrder,
        'created_at': createdAt.toIso8601String(),
      };

  Map<String, dynamic> toJson() => toMap();

  factory Category.fromJson(Map<String, dynamic> json) =>
      Category.fromMap(json);
}
