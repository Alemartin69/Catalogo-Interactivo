import 'package:flutter/material.dart';
import '../models/item.dart';

class ItemCard extends StatelessWidget {
  final Item item;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onFavorite;

  const ItemCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail or header
            Expanded(
              child: item.thumbnailUrl != null
                  ? Image.network(
                      item.thumbnailUrl!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _typeHeader(),
                    )
                  : _typeHeader(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
              child: Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontWeight: FontWeight.w500, fontSize: 13),
              ),
            ),
            Row(
              children: [
                const SizedBox(width: 4),
                _typeChip(),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    item.isFavorite ? Icons.star : Icons.star_border,
                    size: 18,
                    color: item.isFavorite ? Colors.amber : Colors.grey,
                  ),
                  onPressed: onFavorite,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 16),
                  onSelected: (v) {
                    if (v == 'edit') onEdit();
                    if (v == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Editar')),
                    const PopupMenuItem(
                        value: 'delete', child: Text('Eliminar')),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeHeader() {
    return Container(
      color: _typeColor().withOpacity(0.15),
      child: Center(
        child: Icon(_typeIcon(), color: _typeColor(), size: 40),
      ),
    );
  }

  Widget _typeChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _typeColor().withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        item.type.label,
        style: TextStyle(fontSize: 10, color: _typeColor()),
      ),
    );
  }

  Color _typeColor() {
    switch (item.type) {
      case ItemType.video:
        return Colors.red;
      case ItemType.photo:
        return Colors.green;
      case ItemType.file:
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  IconData _typeIcon() {
    switch (item.type) {
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
}
