enum ClothingCategory {
  tops('Tops'),
  bottoms('Bottoms'),
  dresses('Dresses'),
  outerwear('Outerwear'),
  shoes('Shoes'),
  accessories('Accessories');

  const ClothingCategory(this.label);
  final String label;
}

enum ClothingSeason {
  spring('Spring'),
  summer('Summer'),
  autumn('Autumn'),
  winter('Winter'),
  allSeasons('All seasons');

  const ClothingSeason(this.label);
  final String label;
}

/// User-entered metadata. An image reference is currently a local file path.
class ClothingItem {
  const ClothingItem({
    required this.id,
    required this.name,
    required this.category,
    required this.color,
    required this.season,
    this.imageReference,
  });

  final String id;
  final String name;
  final ClothingCategory category;
  final String color;
  final ClothingSeason season;
  final String? imageReference;
}

/// Null means All; filtering preserves repository order.
List<ClothingItem> filterClothingItems(
  Iterable<ClothingItem> items,
  ClothingCategory? category,
) => List.unmodifiable(
  items.where((item) => category == null || item.category == category),
);
