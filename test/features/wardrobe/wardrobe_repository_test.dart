import 'package:flutter_test/flutter_test.dart';
import 'package:wardrobe_plus/features/wardrobe/data/in_memory_wardrobe_repository.dart';
import 'package:wardrobe_plus/features/wardrobe/domain/clothing_item.dart';

void main() {
  Future<ClothingItem> add(
    InMemoryWardrobeRepository repo, {
    String name = ' Shirt ',
    ClothingCategory category = ClothingCategory.tops,
    String? size,
    String? subcategory,
    String? style,
  }) => repo.create(
    name: name,
    category: category,
    color: ' White ',
    season: ClothingSeason.summer,
    size: size,
    subcategory: subcategory,
    style: style,
  );

  test('Create trims metadata and generates unique stable IDs', () async {
    final repo = InMemoryWardrobeRepository();
    final first = await add(
      repo,
      size: ' m ',
      subcategory: ' T-shirt ',
      style: ' Casual ',
    );
    final second = await add(repo);
    expect(first.name, 'Shirt');
    expect(first.color, 'White');
    expect(first.size, 'M');
    expect(first.subcategory, 'T-shirt');
    expect(first.style, 'Casual');
    expect(first.id, isNot(second.id));
    expect(await repo.getById(first.id), same(first));
    expect(await repo.getById('unknown'), isNull);
    expect((await repo.getAll()).length, 2);
  });

  test(
    'Update preserves ID, replaces all metadata, and removes an image',
    () async {
      final repo = InMemoryWardrobeRepository();
      final item = await repo.create(
        name: 'Jacket',
        category: ClothingCategory.outerwear,
        color: 'Olive',
        season: ClothingSeason.winter,
        imageReference: '/photo.jpg',
      );
      await repo.update(
        ClothingItem(
          id: item.id,
          name: 'Summer shirt',
          category: ClothingCategory.tops,
          color: 'Blue',
          season: ClothingSeason.summer,
          size: 'L',
          subcategory: 'Linen shirt',
          style: 'Smart casual',
        ),
      );
      final updated = (await repo.getById(item.id))!;
      expect(updated.id, item.id);
      expect(updated.name, 'Summer shirt');
      expect(updated.category, ClothingCategory.tops);
      expect(updated.color, 'Blue');
      expect(updated.season, ClothingSeason.summer);
      expect(updated.size, 'L');
      expect(updated.subcategory, 'Linen shirt');
      expect(updated.style, 'Smart casual');
      expect(updated.imageReference, isNull);
      expect((await repo.getAll()).length, 1);
    },
  );

  test(
    'Delete removes only the selected item; missing mutations fail',
    () async {
      final repo = InMemoryWardrobeRepository();
      final first = await add(repo);
      final second = await add(repo);
      await repo.delete(first.id);
      expect(await repo.getById(first.id), isNull);
      expect(await repo.getAll(), [second]);
      await expectLater(repo.delete(first.id), throwsStateError);
      await expectLater(repo.update(first), throwsStateError);
    },
  );

  test('Invalid metadata cannot enter the repository', () async {
    final repo = InMemoryWardrobeRepository();
    await expectLater(add(repo, name: '  '), throwsArgumentError);
    await expectLater(add(repo, name: 'a' * 81), throwsArgumentError);
    expect(await repo.getAll(), isEmpty);
    expect(
      () => InMemoryWardrobeRepository(
        initialItems: const [
          ClothingItem(
            id: '',
            name: 'Shirt',
            category: ClothingCategory.tops,
            color: 'White',
            season: ClothingSeason.summer,
          ),
        ],
      ),
      throwsArgumentError,
    );
  });

  test(
    'Existing records remain compatible without optional metadata',
    () async {
      const legacy = ClothingItem(
        id: 'legacy-1',
        name: 'Legacy coat',
        category: ClothingCategory.outerwear,
        color: 'Black',
        season: ClothingSeason.winter,
      );
      final repo = InMemoryWardrobeRepository(initialItems: const [legacy]);
      final stored = (await repo.getAll()).single;
      expect(stored.size, isNull);
      expect(stored.subcategory, isNull);
      expect(stored.style, isNull);
    },
  );

  test(
    'Category size rules accept valid formats and reject invalid ones',
    () async {
      final repo = InMemoryWardrobeRepository();
      expect((await add(repo, size: 'XXL')).size, 'XXL');
      expect(
        (await add(
          repo,
          category: ClothingCategory.bottoms,
          size: ' w32 / l34 ',
        )).size,
        'W32/L34',
      );
      expect(
        (await add(repo, category: ClothingCategory.shoes, size: '42.5')).size,
        '42.5',
      );
      expect(
        (await add(
          repo,
          category: ClothingCategory.accessories,
          size: 'One size',
        )).size,
        'One size',
      );

      await expectLater(add(repo, size: '32'), throwsArgumentError);
      await expectLater(
        add(repo, category: ClothingCategory.bottoms, size: 'Medium'),
        throwsArgumentError,
      );
      await expectLater(
        add(repo, category: ClothingCategory.shoes, size: 'EU 42'),
        throwsArgumentError,
      );
    },
  );

  test(
    'Snapshots cannot mutate storage and do not change after later writes',
    () async {
      final repo = InMemoryWardrobeRepository();
      final snapshot = await repo.getAll();
      final item = await add(repo);
      expect(() => snapshot.add(item), throwsUnsupportedError);
      expect(snapshot, isEmpty);
      expect((await repo.getAll()).length, 1);
    },
  );

  test(
    'Seeds are realistic, separate per instance, and reject duplicate IDs',
    () async {
      final repo = InMemoryWardrobeRepository.seeded();
      final seed = await repo.getAll();
      expect(seed.length, 3);
      expect(seed.map((item) => item.category).toSet().length, 3);
      await repo.delete(seed.first.id);
      expect((await InMemoryWardrobeRepository.seeded().getAll()).length, 3);
      expect(
        () =>
            InMemoryWardrobeRepository(initialItems: [seed.first, seed.first]),
        throwsArgumentError,
      );
    },
  );

  test(
    'Filtering supports All, matching categories, no match, and empty input',
    () async {
      final items = await InMemoryWardrobeRepository.seeded().getAll();
      expect(filterClothingItems(items, null), items);
      expect(
        filterClothingItems(items, ClothingCategory.tops).single.name,
        'White cotton shirt',
      );
      expect(filterClothingItems(items, ClothingCategory.dresses), isEmpty);
      expect(filterClothingItems([], null), isEmpty);
      expect(items.length, 3);
      expect(
        () => filterClothingItems(items, null).clear(),
        throwsUnsupportedError,
      );
    },
  );
}
