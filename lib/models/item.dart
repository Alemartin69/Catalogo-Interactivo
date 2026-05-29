enum ItemType { video, webpage, photo, file }

extension ItemTypeExtension on ItemType {
  String get label {
    switch (this) {
      case ItemType.video:
        return 'Video';
      case ItemType.webpage:
        return 'Página web';
      case ItemType.photo:
        return 'Foto';
      case ItemType.file:
        return 'Archivo';
    }
  }

  String get iconName {
    switch (this) {
      case ItemType.video:
        return 'videocam';
      case ItemType.webpage:
        return 'language';
      case ItemType.photo:
        return 'photo';
      case ItemType.file:
        return 'insert_drive_file';
    }
  }
}

ItemType itemTypeFromString(String s) {
  switch (s) {
    case 'video':
      return ItemType.video;
    case 'photo':
      return ItemType.photo;
    case 'file':
      return ItemType.file;
    default:
      return ItemType.webpage;
  }
}

class Item {
  final String id;
  String title;
  String url;
  ItemType type;
  String categoryId;
  String? subcategoryId;
  String? description;
  String? thumbnailUrl;
  List<String> tags;
  bool isFavorite;
  final DateTime createdAt;
  DateTime updatedAt;

  Item({
    required this.id,
    required this.title,
    required this.url,
    required this.type,
    required this.categoryId,
    this.subcategoryId,
    this.description,
    this.thumbnailUrl,
    this.tags = const [],
    this.isFavorite = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Item.fromMap(Map<String, dynamic> map) => Item(
        id: map['id'] as String,
        title: map['title'] as String,
        url: map['url'] as String,
        type: itemTypeFromString(map['type'] as String),
        categoryId: map['category_id'] as String,
        subcategoryId: map['subcategory_id'] as String?,
        description: map['description'] as String?,
        thumbnailUrl: map['thumbnail_url'] as String?,
        tags: map['tags'] != null
            ? (map['tags'] as String)
                .split(',')
                .where((t) => t.isNotEmpty)
                .toList()
            : [],
        isFavorite: (map['is_favorite'] as int?) == 1,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'url': url,
        'type': type.name,
        'category_id': categoryId,
        'subcategory_id': subcategoryId,
        'description': description,
        'thumbnail_url': thumbnailUrl,
        'tags': tags.join(','),
        'is_favorite': isFavorite ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  Map<String, dynamic> toJson() {
    final map = toMap();
    map['tags'] = tags;
    map['is_favorite'] = isFavorite;
    return map;
  }

  factory Item.fromJson(Map<String, dynamic> json) => Item(
        id: json['id'] as String,
        title: json['title'] as String,
        url: json['url'] as String,
        type: itemTypeFromString(json['type'] as String),
        categoryId: json['category_id'] as String,
        subcategoryId: json['subcategory_id'] as String?,
        description: json['description'] as String?,
        thumbnailUrl: json['thumbnail_url'] as String?,
        tags: json['tags'] is List
            ? List<String>.from(json['tags'] as List)
            : [],
        isFavorite: (json['is_favorite'] as bool?) ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );
}
