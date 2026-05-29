import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/category.dart';
import '../models/subcategory.dart';
import '../models/item.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _db;

  DatabaseHelper._internal();

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = join(docsDir.path, 'catalogo.db');

    return openDatabase(
      dbPath,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        icon TEXT,
        sort_order INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE subcategories (
        id TEXT PRIMARY KEY,
        category_id TEXT NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        sort_order INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE items (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        url TEXT NOT NULL,
        type TEXT NOT NULL,
        category_id TEXT NOT NULL,
        subcategory_id TEXT,
        description TEXT,
        thumbnail_url TEXT,
        tags TEXT DEFAULT '',
        is_favorite INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE,
        FOREIGN KEY (subcategory_id) REFERENCES subcategories(id) ON DELETE SET NULL
      )
    ''');
  }

  // Categories
  Future<List<Category>> getCategories() async {
    final db = await database;
    final maps = await db.query('categories', orderBy: 'sort_order ASC, name ASC');
    return maps.map(Category.fromMap).toList();
  }

  Future<void> insertCategory(Category cat) async {
    final db = await database;
    await db.insert('categories', cat.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateCategory(Category cat) async {
    final db = await database;
    await db.update('categories', cat.toMap(),
        where: 'id = ?', whereArgs: [cat.id]);
  }

  Future<void> deleteCategory(String id) async {
    final db = await database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // Subcategories
  Future<List<Subcategory>> getSubcategories(String categoryId) async {
    final db = await database;
    final maps = await db.query('subcategories',
        where: 'category_id = ?',
        whereArgs: [categoryId],
        orderBy: 'sort_order ASC, name ASC');
    return maps.map(Subcategory.fromMap).toList();
  }

  Future<List<Subcategory>> getAllSubcategories() async {
    final db = await database;
    final maps = await db.query('subcategories', orderBy: 'name ASC');
    return maps.map(Subcategory.fromMap).toList();
  }

  Future<void> insertSubcategory(Subcategory sub) async {
    final db = await database;
    await db.insert('subcategories', sub.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateSubcategory(Subcategory sub) async {
    final db = await database;
    await db.update('subcategories', sub.toMap(),
        where: 'id = ?', whereArgs: [sub.id]);
  }

  Future<void> deleteSubcategory(String id) async {
    final db = await database;
    await db.delete('subcategories', where: 'id = ?', whereArgs: [id]);
  }

  // Items
  Future<List<Item>> getItems({String? categoryId, String? subcategoryId}) async {
    final db = await database;
    String? where;
    List<dynamic>? whereArgs;

    if (subcategoryId != null) {
      where = 'subcategory_id = ?';
      whereArgs = [subcategoryId];
    } else if (categoryId != null) {
      where = 'category_id = ?';
      whereArgs = [categoryId];
    }

    final maps = await db.query('items',
        where: where, whereArgs: whereArgs, orderBy: 'created_at DESC');
    return maps.map(Item.fromMap).toList();
  }

  Future<List<Item>> getFavorites() async {
    final db = await database;
    final maps = await db.query('items',
        where: 'is_favorite = 1', orderBy: 'updated_at DESC');
    return maps.map(Item.fromMap).toList();
  }

  Future<List<Item>> searchItems(String query) async {
    final db = await database;
    final q = '%${query.toLowerCase()}%';
    final maps = await db.query('items',
        where: 'LOWER(title) LIKE ? OR LOWER(description) LIKE ? OR LOWER(tags) LIKE ? OR LOWER(url) LIKE ?',
        whereArgs: [q, q, q, q],
        orderBy: 'created_at DESC');
    return maps.map(Item.fromMap).toList();
  }

  Future<void> insertItem(Item item) async {
    final db = await database;
    await db.insert('items', item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateItem(Item item) async {
    final db = await database;
    await db.update('items', item.toMap(),
        where: 'id = ?', whereArgs: [item.id]);
  }

  Future<void> deleteItem(String id) async {
    final db = await database;
    await db.delete('items', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, dynamic>> exportAll() async {
    final db = await database;
    final categories = await db.query('categories');
    final subcategories = await db.query('subcategories');
    final items = await db.query('items');
    return {
      'version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'categories': categories,
      'subcategories': subcategories,
      'items': items,
    };
  }

  Future<void> importAll(Map<String, dynamic> data) async {
    final db = await database;
    await db.transaction((txn) async {
      if (data['categories'] != null) {
        for (final c in data['categories'] as List) {
          await txn.insert('categories', Map<String, dynamic>.from(c as Map),
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
      if (data['subcategories'] != null) {
        for (final s in data['subcategories'] as List) {
          await txn.insert('subcategories', Map<String, dynamic>.from(s as Map),
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
      if (data['items'] != null) {
        for (final i in data['items'] as List) {
          await txn.insert('items', Map<String, dynamic>.from(i as Map),
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
    });
  }
}
