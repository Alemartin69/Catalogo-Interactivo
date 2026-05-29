import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/item.dart';
import '../providers/catalog_provider.dart';
import '../utils/url_utils.dart';

class ItemFormScreen extends StatefulWidget {
  final Item? item;

  const ItemFormScreen({super.key, this.item});

  @override
  State<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends State<ItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _urlCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _thumbCtrl;
  late TextEditingController _tagsCtrl;
  ItemType _type = ItemType.webpage;
  String? _categoryId;
  String? _subcategoryId;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _titleCtrl = TextEditingController(text: item?.title ?? '');
    _urlCtrl = TextEditingController(text: item?.url ?? '');
    _descCtrl = TextEditingController(text: item?.description ?? '');
    _thumbCtrl = TextEditingController(text: item?.thumbnailUrl ?? '');
    _tagsCtrl = TextEditingController(text: item?.tags.join(', ') ?? '');
    _type = item?.type ?? ItemType.webpage;
    _categoryId = item?.categoryId;
    _subcategoryId = item?.subcategoryId;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _urlCtrl.dispose();
    _descCtrl.dispose();
    _thumbCtrl.dispose();
    _tagsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CatalogProvider>();
    final subs = _categoryId != null
        ? provider.subcategoriesFor(_categoryId!)
        : <dynamic>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item == null ? 'Nuevo ítem' : 'Editar ítem'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Guardar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Type selector
            const Text('Tipo', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SegmentedButton<ItemType>(
              segments: ItemType.values
                  .map((t) => ButtonSegment(
                        value: t,
                        label: Text(t.label),
                        icon: Icon(_typeIcon(t)),
                      ))
                  .toList(),
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 16),

            // Title
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                  labelText: 'Título *', border: OutlineInputBorder()),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),

            // URL
            TextFormField(
              controller: _urlCtrl,
              decoration: InputDecoration(
                labelText: 'URL *',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.open_in_new),
                  tooltip: 'Probar URL',
                  onPressed: () {
                    if (_urlCtrl.text.isNotEmpty) {
                      openUrl(_urlCtrl.text);
                    }
                  },
                ),
              ),
              keyboardType: TextInputType.url,
              validator: (v) =>
                  v == null || v.isEmpty ? 'Requerido' : null,
              onChanged: (v) {
                final thumb = thumbnailFromUrl(v);
                if (thumb != null && _thumbCtrl.text.isEmpty) {
                  setState(() => _thumbCtrl.text = thumb);
                }
              },
            ),
            const SizedBox(height: 12),

            // Category
            DropdownButtonFormField<String>(
              value: _categoryId,
              decoration: const InputDecoration(
                  labelText: 'Categoría *', border: OutlineInputBorder()),
              items: provider.categories
                  .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                  .toList(),
              onChanged: (v) => setState(() {
                _categoryId = v;
                _subcategoryId = null;
              }),
              validator: (v) => v == null ? 'Seleccioná una categoría' : null,
            ),
            const SizedBox(height: 12),

            // Subcategory
            if (subs.isNotEmpty)
              DropdownButtonFormField<String>(
                value: _subcategoryId,
                decoration: const InputDecoration(
                    labelText: 'Subcategoría',
                    border: OutlineInputBorder()),
                items: [
                  const DropdownMenuItem(
                      value: null, child: Text('— Sin subcategoría —')),
                  ...provider.subcategoriesFor(_categoryId!).map((s) =>
                      DropdownMenuItem(value: s.id, child: Text(s.name))),
                ],
                onChanged: (v) => setState(() => _subcategoryId = v),
              ),
            if (subs.isNotEmpty) const SizedBox(height: 12),

            // Description
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                  labelText: 'Descripción', border: OutlineInputBorder()),
              maxLines: 3,
            ),
            const SizedBox(height: 12),

            // Thumbnail URL
            TextFormField(
              controller: _thumbCtrl,
              decoration: const InputDecoration(
                  labelText: 'URL de miniatura (opcional)',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),

            // Tags
            TextFormField(
              controller: _tagsCtrl,
              decoration: const InputDecoration(
                  labelText: 'Etiquetas (separadas por coma)',
                  border: OutlineInputBorder()),
            ),
          ],
        ),
      ),
    );
  }

  IconData _typeIcon(ItemType t) {
    switch (t) {
      case ItemType.video:
        return Icons.videocam;
      case ItemType.photo:
        return Icons.photo;
      case ItemType.file:
        return Icons.insert_drive_file;
      default:
        return Icons.language;
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<CatalogProvider>();
    final tags = _tagsCtrl.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    if (widget.item == null) {
      final item = Item(
        id: const Uuid().v4(),
        title: _titleCtrl.text.trim(),
        url: _urlCtrl.text.trim(),
        type: _type,
        categoryId: _categoryId!,
        subcategoryId: _subcategoryId,
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        thumbnailUrl: _thumbCtrl.text.trim().isEmpty ? null : _thumbCtrl.text.trim(),
        tags: tags,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      provider.addItem(item);
    } else {
      final item = widget.item!;
      item.title = _titleCtrl.text.trim();
      item.url = _urlCtrl.text.trim();
      item.type = _type;
      item.categoryId = _categoryId!;
      item.subcategoryId = _subcategoryId;
      item.description =
          _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim();
      item.thumbnailUrl =
          _thumbCtrl.text.trim().isEmpty ? null : _thumbCtrl.text.trim();
      item.tags = tags;
      item.updatedAt = DateTime.now();
      provider.updateItem(item);
    }

    Navigator.pop(context);
  }
}
