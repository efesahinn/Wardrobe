import 'clothing_item.dart';

/// Async boundary so a remote repository can replace the development store.
abstract interface class WardrobeRepository {
  Future<List<ClothingItem>> getAll();
  Future<ClothingItem?> getById(String id);
  Future<ClothingItem> create({
    required String name,
    required ClothingCategory category,
    required String color,
    required ClothingSeason season,
    String? imageReference,
  });
  Future<void> update(ClothingItem item);
  Future<void> delete(String id);
}
