import 'package:flutter/foundation.dart' hide Category;
import '../database/database_helper.dart';
import '../models/category.dart';
import '../models/subcategory.dart';
import '../models/item.dart';

class CatalogProvider extends ChangeNotifier {
  final _db = DatabaseHelper.instance;

  List<Category> _categories = [];
  List<Subcategory> _allSubcategories = [];
  List<Item> _currentItems = [];
  List<Item> _searchResults = [];
  bool _isSearching = false;
  String? _selectedCategoryId;
  String? _selectedSubcategoryId;

  List<Category> get categories => _categories;
  List<Item> get currentItems => _isSearching ? _searchResults : _currentItems;
  bool get isSearching => _isSearching;
  String? get selectedCategoryId => _selectedCategoryId;
  String? get selectedSubcategoryId => _selectedSubcategoryId;

  List<Subcategory> subcategoriesFor(String categoryId) =>
      _allSubcategories.where((s) => s.categoryId == categoryId).toList();

  Future<void> loadAll() async {
    _categories = await _db.getCategories();
    _allSubcategories = await _db.getAllSubcategories();
    notifyListeners();
  }

  Future<void> loadItems({String? categoryId, String? subcategoryId}) async {
    _selectedCategoryId = categoryId;
    _selectedSubcategoryId = subcategoryId;
    _isSearching = false;
    _currentItems = await _db.getItems(
        categoryId: categoryId, subcategoryId: subcategoryId);
    notifyListeners();
  }

  Future<void> loadFavorites() async {
    _selectedCategoryId = null;
    _selectedSubcategoryId = null;
    _isSearching = false;
    _currentItems = await _db.getFavorites();
    notifyListeners();
  }

  Future<void> search(String query) async {
    if (query.isEmpty) {
      _isSearching = false;
      notifyListeners();
      return;
    }
    _isSearching = true;
    _searchResults = await _db.searchItems(query);
    notifyListeners();
  }

  void clearSearch() {
    _isSearching = false;
    notifyListeners();
  }

  // Categories
  Future<void> addCategory(Category cat) async {
    await _db.insertCategory(cat);
    await loadAll();
  }

  Future<void> updateCategory(Category cat) async {
    await _db.updateCategory(cat);
    await loadAll();
  }

  Future<void> deleteCategory(String id) async {
    await _db.deleteCategory(id);
    if (_selectedCategoryId == id) {
      _currentItems = [];
      _selectedCategoryId = null;
      _selectedSubcategoryId = null;
    }
    await loadAll();
  }

  // Subcategories
  Future<void> addSubcategory(Subcategory sub) async {
    await _db.insertSubcategory(sub);
    await loadAll();
  }

  Future<void> updateSubcategory(Subcategory sub) async {
    await _db.updateSubcategory(sub);
    await loadAll();
  }

  Future<void> deleteSubcategory(String id) async {
    await _db.deleteSubcategory(id);
    if (_selectedSubcategoryId == id) {
      _selectedSubcategoryId = null;
    }
    await loadAll();
  }

  // Items
  Future<void> addItem(Item item) async {
    await _db.insertItem(item);
    await _refreshCurrentItems();
  }

  Future<void> updateItem(Item item) async {
    await _db.updateItem(item);
    await _refreshCurrentItems();
  }

  Future<void> deleteItem(String id) async {
    await _db.deleteItem(id);
    await _refreshCurrentItems();
  }

  Future<void> toggleFavorite(Item item) async {
    item.isFavorite = !item.isFavorite;
    item.updatedAt = DateTime.now();
    await _db.updateItem(item);
    await _refreshCurrentItems();
  }

  Future<void> _refreshCurrentItems() async {
    _currentItems = await _db.getItems(
        categoryId: _selectedCategoryId,
        subcategoryId: _selectedSubcategoryId);
    notifyListeners();
  }

  Future<Map<String, dynamic>> exportData() => _db.exportAll();

  Future<void> importData(Map<String, dynamic> data) async {
    await _db.importAll(data);
    await loadAll();
    await _refreshCurrentItems();
  }
}
