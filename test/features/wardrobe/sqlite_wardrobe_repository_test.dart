import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:wardrobe_plus/features/wardrobe/data/managed_photo_store.dart';
import 'package:wardrobe_plus/features/wardrobe/data/sqlite_wardrobe_repository.dart';
import 'package:wardrobe_plus/features/wardrobe/domain/clothing_item.dart';

void main() {
  late Directory temporaryDirectory;
  late Directory managedPhotoDirectory;
  late String databasePath;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'wardrobe-persistence-',
    );
    managedPhotoDirectory = Directory(
      '${temporaryDirectory.path}${Platform.pathSeparator}managed_photos',
    );
    databasePath =
        '${temporaryDirectory.path}${Platform.pathSeparator}wardrobe.sqlite';
  });

  tearDown(() async {
    if (await temporaryDirectory.exists()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  SqliteWardrobeRepository repository() => SqliteWardrobeRepository(
    databaseFactory: databaseFactoryFfi,
    databasePath: databasePath,
    photoStore: ManagedPhotoStore(
      directoryProvider: () async => managedPhotoDirectory,
    ),
  );

  test('a new database starts with an empty wardrobe', () async {
    final repo = repository();
    addTearDown(repo.close);

    expect(await repo.getAll(), isEmpty);
  });

  test('all clothing metadata survives closing and reopening SQLite', () async {
    final first = repository();
    final created = await first.create(
      name: '  Linen shirt  ',
      category: ClothingCategory.tops,
      color: '  Blue  ',
      season: ClothingSeason.summer,
      size: ' m ',
      subcategory: '  Button-down  ',
      style: '  Smart casual  ',
    );
    await first.close();

    final restarted = repository();
    addTearDown(restarted.close);
    final restored = (await restarted.getAll()).single;

    expect(restored.id, created.id);
    expect(restored.name, 'Linen shirt');
    expect(restored.category, ClothingCategory.tops);
    expect(restored.color, 'Blue');
    expect(restored.season, ClothingSeason.summer);
    expect(restored.size, 'M');
    expect(restored.subcategory, 'Button-down');
    expect(restored.style, 'Smart casual');
    expect(restored.imageReference, isNull);
  });

  test(
    'managed photos persist, are replaced safely, and are deleted',
    () async {
      final originalGalleryPhoto = File(
        '${temporaryDirectory.path}${Platform.pathSeparator}gallery.jpg',
      );
      final originalCameraPhoto = File(
        '${temporaryDirectory.path}${Platform.pathSeparator}camera.png',
      );
      await originalGalleryPhoto.writeAsBytes([1, 2, 3, 4]);
      await originalCameraPhoto.writeAsBytes([5, 6, 7, 8]);

      final first = repository();
      final created = await first.create(
        name: 'Coat',
        category: ClothingCategory.outerwear,
        color: 'Black',
        season: ClothingSeason.winter,
        imageReference: originalGalleryPhoto.path,
      );
      final firstManagedPath = created.imageReference!;
      expect(firstManagedPath, isNot(originalGalleryPhoto.path));
      expect(await File(firstManagedPath).readAsBytes(), [1, 2, 3, 4]);
      expect(await originalGalleryPhoto.exists(), isTrue);
      await first.close();

      final restarted = repository();
      var restored = (await restarted.getAll()).single;
      expect(restored.imageReference, firstManagedPath);
      expect(await File(firstManagedPath).exists(), isTrue);

      await restarted.update(
        ClothingItem(
          id: restored.id,
          name: restored.name,
          category: restored.category,
          color: restored.color,
          season: restored.season,
          imageReference: originalCameraPhoto.path,
        ),
      );
      restored = (await restarted.getById(restored.id))!;
      final replacementManagedPath = restored.imageReference!;
      expect(replacementManagedPath, isNot(originalCameraPhoto.path));
      expect(await File(firstManagedPath).exists(), isFalse);
      expect(await originalGalleryPhoto.exists(), isTrue);
      expect(await originalCameraPhoto.exists(), isTrue);

      await restarted.delete(restored.id);
      expect(await File(replacementManagedPath).exists(), isFalse);
      expect(await originalGalleryPhoto.exists(), isTrue);
      expect(await originalCameraPhoto.exists(), isTrue);
      expect(await restarted.getAll(), isEmpty);
      await restarted.close();
    },
  );
}
