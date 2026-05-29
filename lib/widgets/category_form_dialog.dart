import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/category.dart';

class CategoryFormDialog extends StatefulWidget {
  final Category? category;
  final Future<void> Function(Category) onSave;

  const CategoryFormDialog({super.key, this.category, required this.onSave});

  @override
  State<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<CategoryFormDialog> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _icon = 'folder';

  static const _icons = [
    'folder', 'videocam', 'photo', 'language', 'star',
    'music_note', 'book', 'work',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameCtrl.text = widget.category!.name;
      _descCtrl.text = widget.category!.description ?? '';
      _icon = widget.category!.icon ?? 'folder';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.category == null ? 'Nueva categoría' : 'Editar categoría'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                  labelText: 'Nombre *', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                  labelText: 'Descripción', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            const Align(
                alignment: Alignment.centerLeft,
                child: Text('Ícono')),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _icons.map((ic) => _iconChip(ic)).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        FilledButton(
          onPressed: _save,
          child: const Text('Guardar'),
        ),
      ],
    );
  }

  Widget _iconChip(String iconName) {
    final isSelected = _icon == iconName;
    return GestureDetector(
      onTap: () => setState(() => _icon = iconName),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey.shade300),
        ),
        child: Icon(_iconData(iconName), size: 22),
      ),
    );
  }

  IconData _iconData(String name) {
    switch (name) {
      case 'videocam': return Icons.videocam;
      case 'photo': return Icons.photo;
      case 'language': return Icons.language;
      case 'star': return Icons.star;
      case 'music_note': return Icons.music_note;
      case 'book': return Icons.book;
      case 'work': return Icons.work;
      default: return Icons.folder;
    }
  }

  void _save() {
    if (_nameCtrl.text.trim().isEmpty) return;
    final cat = widget.category != null
        ? (widget.category!
          ..name = _nameCtrl.text.trim()
          ..description = _descCtrl.text.trim().isEmpty
              ? null
              : _descCtrl.text.trim()
          ..icon = _icon)
        : Category(
            id: const Uuid().v4(),
            name: _nameCtrl.text.trim(),
            description: _descCtrl.text.trim().isEmpty
                ? null
                : _descCtrl.text.trim(),
            icon: _icon,
            createdAt: DateTime.now(),
          );
    widget.onSave(cat);
    Navigator.pop(context);
  }
}
