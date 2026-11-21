import 'dart:io';

import 'package:sqflite/sqflite.dart' as sqflite;

import '../domain/clothing_item.dart';
import '../domain/clothing_metadata.dart';
import '../domain/wardrobe_repository.dart';
import 'managed_photo_store.dart';

class SqliteWardrobeRepository implements WardrobeRepository {
  SqliteWardrobeRepository({
    this.databaseFactory,
    this.databasePath,
    ManagedPhotoStore? photoStore,
  }) : _photoStore = photoStore ?? ManagedPhotoStore();

  static const _databaseName = 'wardrobe.db';
  static const _table = 'clothing_items';

  final sqflite.DatabaseFactory? databaseFactory;
  final String? databasePath;
  final ManagedPhotoStore _photoStore;
  Future<sqflite.Database>? _openingDatabase;

  Future<sqflite.Database> _database() async {
    final existing = _openingDatabase;
    if (existing != null) return existing;
    final opening = _openDatabase();
    _openingDatabase = opening;
    try {
      return await opening;
    } catch (_) {
      if (identical(_openingDatabase, opening)) _openingDatabase = null;
      rethrow;
    }
  }

  Future<sqflite.Database> _openDatabase() async {
    final path =
        databasePath ??
        '${await sqflite.getDatabasesPath()}${Platform.pathSeparator}$_databaseName';
    final factory = databaseFactory ?? sqflite.databaseFactory;
    return factory.openDatabase(
      path,
      options: sqflite.OpenDatabaseOptions(
        version: 1,
        onCreate: (database, version) => database.execute('''
          CREATE TABLE $_table (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            category TEXT NOT NULL,
            color TEXT NOT NULL,
            season TEXT NOT NULL,
            size TEXT,
            subcategory TEXT,
            style TEXT,
            image_reference TEXT
          )
        '''),
      ),
    );
  }

  @override
  Future<List<ClothingItem>> getAll() async {
    final rows = await (await _database()).query(_table, orderBy: 'id ASC');
    return List.unmodifiable(rows.map(_fromRow));
  }

  @override
  Future<ClothingItem?> getById(String id) async {
    final numericId = int.tryParse(id);
    if (numericId == null) return null;
    final rows = await (await _database()).query(
      _table,
      where: 'id = ?',
      whereArgs: [numericId],
      limit: 1,
    );
    return rows.isEmpty ? null : _fromRow(rows.single);
  }

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
    final normalized = _validated(
      ClothingItem(
        id: 'pending',
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
    String? managedPhoto;
    try {
      managedPhoto = await _copyPhoto(normalized.imageReference);
      final id = await (await _database()).insert(
        _table,
        _values(normalized, imageReference: managedPhoto),
      );
      return ClothingItem(
        id: '$id',
        name: normalized.name,
        category: normalized.category,
        color: normalized.color,
        season: normalized.season,
        size: normalized.size,
        subcategory: normalized.subcategory,
        style: normalized.style,
        imageReference: managedPhoto,
      );
    } catch (_) {
      await _deletePhotoBestEffort(managedPhoto);
      rethrow;
    }
  }

  @override
  Future<void> update(ClothingItem item) async {
    final normalized = _validated(item);
    final previous = await getById(item.id);
    if (previous == null) throw StateError('Clothing item not found.');
    final imageChanged = normalized.imageReference != previous.imageReference;
    String? managedPhoto = previous.imageReference;
    if (imageChanged) {
      managedPhoto = await _copyPhoto(normalized.imageReference);
    }
    try {
      final changed = await (await _database()).update(
        _table,
        _values(normalized, imageReference: managedPhoto),
        where: 'id = ?',
        whereArgs: [int.parse(item.id)],
      );
      if (changed != 1) throw StateError('Clothing item not found.');
    } catch (_) {
      if (imageChanged) await _deletePhotoBestEffort(managedPhoto);
      rethrow;
    }
    if (imageChanged) {
      await _deletePhotoBestEffort(previous.imageReference);
    }
  }

  @override
  Future<void> delete(String id) async {
    final previous = await getById(id);
    if (previous == null) throw StateError('Clothing item not found.');
    final deleted = await (await _database()).delete(
      _table,
      where: 'id = ?',
      whereArgs: [int.parse(id)],
    );
    if (deleted != 1) throw StateError('Clothing item not found.');
    await _deletePhotoBestEffort(previous.imageReference);
  }

  Future<void> close() async {
    final opening = _openingDatabase;
    _openingDatabase = null;
    if (opening != null) await (await opening).close();
  }

  Future<String?> _copyPhoto(String? sourcePath) async {
    if (sourcePath == null || sourcePath.trim().isEmpty) return null;
    return _photoStore.copyIntoManagedStorage(sourcePath);
  }

  Future<void> _deletePhotoBestEffort(String? path) async {
    try {
      await _photoStore.deleteIfManaged(path);
    } catch (_) {
      // Database mutations remain successful if orphan cleanup is unavailable.
    }
  }

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

  Map<String, Object?> _values(
    ClothingItem item, {
    required String? imageReference,
  }) => {
    'name': item.name,
    'category': item.category.name,
    'color': item.color,
    'season': item.season.name,
    'size': item.size,
    'subcategory': item.subcategory,
    'style': item.style,
    'image_reference': imageReference,
  };

  ClothingItem _fromRow(Map<String, Object?> row) => ClothingItem(
    id: '${row['id']}',
    name: row['name']! as String,
    category: ClothingCategory.values.byName(row['category']! as String),
    color: row['color']! as String,
    season: ClothingSeason.values.byName(row['season']! as String),
    size: row['size'] as String?,
    subcategory: row['subcategory'] as String?,
    style: row['style'] as String?,
    imageReference: row['image_reference'] as String?,
  );
}
