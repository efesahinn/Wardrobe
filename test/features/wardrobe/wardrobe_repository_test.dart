import 'package:flutter_test/flutter_test.dart';
import 'package:wardrobe_plus/features/wardrobe/data/in_memory_wardrobe_repository.dart';
import 'package:wardrobe_plus/features/wardrobe/domain/clothing_item.dart';

void main() {
  Future<ClothingItem> add(
    InMemoryWardrobeRepository repo, {
    String name = ' Shirt ',
  }) => repo.create(
    name: name,
    category: ClothingCategory.tops,
    color: ' White ',
    season: ClothingSeason.summer,
  );

  test('Create trims metadata and generates unique stable IDs', () async {
    final repo = InMemoryWardrobeRepository();
    final first = await add(repo);
    final second = await add(repo);
    expect(first.name, 'Shirt');
    expect(first.color, 'White');
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
        ),
      );
      final updated = (await repo.getById(item.id))!;
      expect(updated.id, item.id);
      expect(updated.name, 'Summer shirt');
      expect(updated.category, ClothingCategory.tops);
      expect(updated.color, 'Blue');
      expect(updated.season, ClothingSeason.summer);
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
