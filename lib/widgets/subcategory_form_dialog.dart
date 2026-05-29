import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/subcategory.dart';

class SubcategoryFormDialog extends StatefulWidget {
  final String categoryId;
  final Subcategory? subcategory;
  final Future<void> Function(Subcategory) onSave;

  const SubcategoryFormDialog({
    super.key,
    required this.categoryId,
    this.subcategory,
    required this.onSave,
  });

  @override
  State<SubcategoryFormDialog> createState() => _SubcategoryFormDialogState();
}

class _SubcategoryFormDialogState extends State<SubcategoryFormDialog> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.subcategory != null) {
      _nameCtrl.text = widget.subcategory!.name;
      _descCtrl.text = widget.subcategory!.description ?? '';
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
      title: Text(widget.subcategory == null
          ? 'Nueva subcategoría'
          : 'Editar subcategoría'),
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
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        FilledButton(onPressed: _save, child: const Text('Guardar')),
      ],
    );
  }

  void _save() {
    if (_nameCtrl.text.trim().isEmpty) return;
    final sub = widget.subcategory != null
        ? (widget.subcategory!
          ..name = _nameCtrl.text.trim()
          ..description = _descCtrl.text.trim().isEmpty
              ? null
              : _descCtrl.text.trim())
        : Subcategory(
            id: const Uuid().v4(),
            categoryId: widget.categoryId,
            name: _nameCtrl.text.trim(),
            description: _descCtrl.text.trim().isEmpty
                ? null
                : _descCtrl.text.trim(),
            createdAt: DateTime.now(),
          );
    widget.onSave(sub);
    Navigator.pop(context);
  }
}
