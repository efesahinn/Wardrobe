import '../domain/clothing_item.dart';
import '../domain/clothing_metadata.dart';
import '../domain/wardrobe_repository.dart';

class InMemoryWardrobeRepository implements WardrobeRepository {
  InMemoryWardrobeRepository({Iterable<ClothingItem> initialItems = const []}) {
    for (final item in initialItems) {
      if (_items.containsKey(item.id)) {
        throw ArgumentError('Duplicate clothing ID.');
      }
      _items[item.id] = _validated(item);
    }
  }

  factory InMemoryWardrobeRepository.seeded() => InMemoryWardrobeRepository(
    initialItems: const [
      ClothingItem(
        id: 'sample-1',
        name: 'White cotton shirt',
        category: ClothingCategory.tops,
        color: 'White',
        season: ClothingSeason.allSeasons,
      ),
      ClothingItem(
        id: 'sample-2',
        name: 'Indigo jeans',
        category: ClothingCategory.bottoms,
        color: 'Indigo',
        season: ClothingSeason.allSeasons,
      ),
      ClothingItem(
        id: 'sample-3',
        name: 'Olive rain jacket',
        category: ClothingCategory.outerwear,
        color: 'Olive',
        season: ClothingSeason.autumn,
      ),
    ],
  );

  final Map<String, ClothingItem> _items = {};
  int _nextId = 0;

  ClothingItem _validated(ClothingItem item) {
    final sizeError = ClothingMetadataRules.validateSize(
      item.category,
      item.size,
    );
    final subcategoryError = ClothingMetadataRules.validateOptionalText(
      item.subcategory,
      'Subcategory',
    );
    final styleError = ClothingMetadataRules.validateOptionalText(
      item.style,
      'Style',
    );
    if (item.id.trim().isEmpty ||
        item.name.trim().isEmpty ||
        item.name.trim().length > 80 ||
        item.color.trim().isEmpty ||
        item.color.trim().length > 40 ||
        sizeError != null ||
        subcategoryError != null ||
        styleError != null) {
      throw ArgumentError('A valid ID, name, and color are required.');
    }
    return ClothingItem(
      id: item.id,
      name: item.name.trim(),
      category: item.category,
      color: item.color.trim(),
      season: item.season,
      size: ClothingMetadataRules.normalizedSize(item.category, item.size),
      subcategory: ClothingMetadataRules.normalizedOptionalText(
        item.subcategory,
      ),
      style: ClothingMetadataRules.normalizedOptionalText(item.style),
      imageReference: item.imageReference,
    );
  }

  @override
  Future<List<ClothingItem>> getAll() async => List.unmodifiable(_items.values);

  @override
  Future<ClothingItem?> getById(String id) async => _items[id];

  @override
  Future<ClothingItem> create({
    required String name,
    required ClothingCategory category,
    required String color,
    required ClothingSeason season,
    String? size,
    String? subcategory,
    String? style,
    String? imageReference,
  }) async {
    String id;
    do {
      id = 'clothing-${++_nextId}';
    } while (_items.containsKey(id));
    final item = _validated(
      ClothingItem(
        id: id,
        name: name,
        category: category,
        color: color,
        season: season,
        size: size,
        subcategory: subcategory,
        style: style,
        imageReference: imageReference,
      ),
    );
    _items[id] = item;
    return item;
  }

  @override
  Future<void> update(ClothingItem item) async {
    if (!_items.containsKey(item.id)) {
      throw StateError('Clothing item not found.');
    }
    _items[item.id] = _validated(item);
  }

  @override
  Future<void> delete(String id) async {
    if (_items.remove(id) == null) throw StateError('Clothing item not found.');
  }
}
