import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import '../models/item.dart';
import '../providers/catalog_provider.dart';
import '../utils/url_utils.dart';
import '../screens/item_form_screen.dart';
import 'item_card.dart';

class ItemList extends StatelessWidget {
  const ItemList({super.key});

  @override
  Widget build(BuildContext context) {
    final items = context.watch<CatalogProvider>().currentItems;

    if (items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No hay ítems aquí',
                style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );
    }

    final isWide = MediaQuery.of(context).size.width > 900;

    if (isWide) {
      return GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 280,
          mainAxisExtent: 180,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: items.length,
        itemBuilder: (ctx, i) => ItemCard(
          item: items[i],
          onTap: () => openUrl(items[i].url),
          onEdit: () => _editItem(ctx, items[i]),
          onDelete: () =>
              ctx.read<CatalogProvider>().deleteItem(items[i].id),
          onFavorite: () =>
              ctx.read<CatalogProvider>().toggleFavorite(items[i]),
        ),
      );
    }

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (ctx, i) => _buildSlidableItem(ctx, items[i]),
    );
  }

  Widget _buildSlidableItem(BuildContext ctx, Item item) {
    final provider = ctx.read<CatalogProvider>();
    return Slidable(
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => provider.toggleFavorite(item),
            backgroundColor: Colors.amber,
            icon: item.isFavorite ? Icons.star : Icons.star_border,
            label: 'Fav',
          ),
          SlidableAction(
            onPressed: (_) => _editItem(ctx, item),
            backgroundColor: Colors.blue,
            icon: Icons.edit,
            label: 'Editar',
          ),
          SlidableAction(
            onPressed: (_) => provider.deleteItem(item.id),
            backgroundColor: Colors.red,
            icon: Icons.delete,
            label: 'Borrar',
          ),
        ],
      ),
      child: ListTile(
        leading: _ItemLeading(item: item),
        title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(item.url,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _typeChip(item.type),
            if (item.isFavorite)
              const Icon(Icons.star, color: Colors.amber, size: 18),
          ],
        ),
        onTap: () => openUrl(item.url),
      ),
    );
  }

  Widget _typeChip(ItemType type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _typeColor(type).withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        type.label,
        style: TextStyle(fontSize: 11, color: _typeColor(type)),
      ),
    );
  }

  Color _typeColor(ItemType type) {
    switch (type) {
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

  void _editItem(BuildContext ctx, Item item) {
    Navigator.push(
        ctx, MaterialPageRoute(builder: (_) => ItemFormScreen(item: item)));
  }
}

class _ItemLeading extends StatelessWidget {
  final Item item;
  const _ItemLeading({required this.item});

  @override
  Widget build(BuildContext context) {
    if (item.thumbnailUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.network(
          item.thumbnailUrl!,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallbackIcon(),
        ),
      );
    }
    return _fallbackIcon();
  }

  Widget _fallbackIcon() {
    return CircleAvatar(
      backgroundColor: _typeColor(item.type).withOpacity(0.15),
      child: Icon(_typeIcon(item.type), color: _typeColor(item.type)),
    );
  }

  Color _typeColor(ItemType type) {
    switch (type) {
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

  IconData _typeIcon(ItemType type) {
    switch (type) {
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
