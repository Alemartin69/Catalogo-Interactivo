import 'package:flutter/material.dart' hide Category;
import 'package:provider/provider.dart';
import '../providers/catalog_provider.dart';
import '../models/category.dart';
import '../models/subcategory.dart';
import '../widgets/item_list.dart';
import '../widgets/category_form_dialog.dart';
import '../widgets/subcategory_form_dialog.dart';
import 'item_form_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  String? _expandedCategoryId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CatalogProvider>().loadAll();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CatalogProvider>();
    final isWide = MediaQuery.of(context).size.width > 700;

    if (isWide) {
      return _buildWideLayout(provider);
    }
    return _buildNarrowLayout(provider);
  }

  Widget _buildWideLayout(CatalogProvider provider) {
    return Scaffold(
      appBar: _buildAppBar(provider),
      body: Row(
        children: [
          SizedBox(
            width: 260,
            child: _buildSidebar(provider),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              children: [
                _buildSearchBar(provider),
                Expanded(child: ItemList()),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFab(provider),
    );
  }

  Widget _buildNarrowLayout(CatalogProvider provider) {
    return Scaffold(
      appBar: _buildAppBar(provider),
      drawer: Drawer(child: _buildSidebar(provider)),
      body: Column(
        children: [
          _buildSearchBar(provider),
          Expanded(child: ItemList()),
        ],
      ),
      floatingActionButton: _buildFab(provider),
    );
  }

  PreferredSizeWidget _buildAppBar(CatalogProvider provider) {
    return AppBar(
      title: const Text('Catálogo Interactivo'),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings),
          tooltip: 'Configuración',
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const SettingsScreen())),
        ),
      ],
    );
  }

  Widget _buildSearchBar(CatalogProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    provider.clearSearch();
                  },
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          isDense: true,
        ),
        onChanged: (q) => provider.search(q),
      ),
    );
  }

  Widget _buildSidebar(CatalogProvider provider) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.grid_view),
          title: const Text('Todos'),
          selected: provider.selectedCategoryId == null && !provider.isSearching,
          onTap: () => provider.loadItems(),
        ),
        ListTile(
          leading: const Icon(Icons.favorite),
          title: const Text('Favoritos'),
          onTap: () => provider.loadFavorites(),
        ),
        const Divider(),
        Expanded(
          child: ListView.builder(
            itemCount: provider.categories.length,
            itemBuilder: (ctx, i) =>
                _buildCategoryTile(provider, provider.categories[i]),
          ),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.add),
          title: const Text('Nueva categoría'),
          onTap: () => _showCategoryDialog(context, provider),
        ),
      ],
    );
  }

  Widget _buildCategoryTile(CatalogProvider provider, Category cat) {
    final subs = provider.subcategoriesFor(cat.id);
    final isExpanded = _expandedCategoryId == cat.id;
    final isSelected = provider.selectedCategoryId == cat.id &&
        provider.selectedSubcategoryId == null;

    return Column(
      children: [
        ListTile(
          leading: Icon(_categoryIcon(cat.icon)),
          title: Text(cat.name),
          selected: isSelected,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (subs.isNotEmpty)
                Icon(isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 20),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 18),
                onSelected: (v) => _handleCategoryMenu(v, provider, cat),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Editar')),
                  const PopupMenuItem(
                      value: 'add_sub', child: Text('Agregar subcategoría')),
                  const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                ],
              ),
            ],
          ),
          onTap: () {
            setState(() {
              _expandedCategoryId = isExpanded ? null : cat.id;
            });
            provider.loadItems(categoryId: cat.id);
          },
        ),
        if (isExpanded)
          ...subs.map((sub) => _buildSubcategoryTile(provider, cat, sub)),
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 56),
            child: ListTile(
              leading: const Icon(Icons.add, size: 18),
              title: const Text('Nueva subcategoría',
                  style: TextStyle(fontSize: 13)),
              dense: true,
              onTap: () => _showSubcategoryDialog(context, provider, cat.id),
            ),
          ),
      ],
    );
  }

  Widget _buildSubcategoryTile(
      CatalogProvider provider, Category cat, Subcategory sub) {
    final isSelected = provider.selectedSubcategoryId == sub.id;
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: ListTile(
        leading: const Icon(Icons.subdirectory_arrow_right, size: 18),
        title: Text(sub.name, style: const TextStyle(fontSize: 14)),
        selected: isSelected,
        dense: true,
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, size: 16),
          onSelected: (v) => _handleSubcategoryMenu(v, provider, sub),
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('Editar')),
            const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
          ],
        ),
        onTap: () => provider.loadItems(
            categoryId: cat.id, subcategoryId: sub.id),
      ),
    );
  }

  FloatingActionButton _buildFab(CatalogProvider provider) {
    return FloatingActionButton(
      onPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ItemFormScreen()),
        );
        await provider.loadAll();
        if (provider.selectedCategoryId != null) {
          await provider.loadItems(
              categoryId: provider.selectedCategoryId,
              subcategoryId: provider.selectedSubcategoryId);
        }
      },
      child: const Icon(Icons.add),
    );
  }

  IconData _categoryIcon(String? icon) {
    switch (icon) {
      case 'videocam':
        return Icons.videocam;
      case 'photo':
        return Icons.photo;
      case 'language':
        return Icons.language;
      case 'star':
        return Icons.star;
      case 'music_note':
        return Icons.music_note;
      case 'book':
        return Icons.book;
      case 'work':
        return Icons.work;
      default:
        return Icons.folder;
    }
  }

  void _handleCategoryMenu(
      String action, CatalogProvider provider, Category cat) {
    switch (action) {
      case 'edit':
        _showCategoryDialog(context, provider, cat: cat);
        break;
      case 'add_sub':
        _showSubcategoryDialog(context, provider, cat.id);
        break;
      case 'delete':
        _confirmDelete(
            context, 'categoría "${cat.name}"', () => provider.deleteCategory(cat.id));
        break;
    }
  }

  void _handleSubcategoryMenu(
      String action, CatalogProvider provider, Subcategory sub) {
    switch (action) {
      case 'edit':
        _showSubcategoryDialog(context, provider, sub.categoryId, sub: sub);
        break;
      case 'delete':
        _confirmDelete(context, 'subcategoría "${sub.name}"',
            () => provider.deleteSubcategory(sub.id));
        break;
    }
  }

  void _showCategoryDialog(BuildContext ctx, CatalogProvider provider,
      {Category? cat}) {
    showDialog(
      context: ctx,
      builder: (_) => CategoryFormDialog(
        category: cat,
        onSave: (c) => cat == null
            ? provider.addCategory(c)
            : provider.updateCategory(c),
      ),
    );
  }

  void _showSubcategoryDialog(
      BuildContext ctx, CatalogProvider provider, String categoryId,
      {Subcategory? sub}) {
    showDialog(
      context: ctx,
      builder: (_) => SubcategoryFormDialog(
        categoryId: categoryId,
        subcategory: sub,
        onSave: (s) => sub == null
            ? provider.addSubcategory(s)
            : provider.updateSubcategory(s),
      ),
    );
  }

  void _confirmDelete(
      BuildContext ctx, String label, VoidCallback onConfirm) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Eliminar $label? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
