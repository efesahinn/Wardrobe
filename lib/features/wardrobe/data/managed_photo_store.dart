import 'dart:io';

import 'package:path_provider/path_provider.dart';

typedef PhotoDirectoryProvider = Future<Directory> Function();

class ManagedPhotoStore {
  ManagedPhotoStore({PhotoDirectoryProvider? directoryProvider})
    : _directoryProvider = directoryProvider ?? _defaultPhotoDirectoryProvider;

  final PhotoDirectoryProvider _directoryProvider;
  Future<Directory>? _directoryFuture;
  int _sequence = 0;

  static Future<Directory> _defaultPhotoDirectoryProvider() async {
    final documents = await getApplicationDocumentsDirectory();
    return Directory(
      '${documents.path}${Platform.pathSeparator}wardrobe_photos',
    );
  }

  Future<Directory> _directory() async {
    final existing = _directoryFuture;
    if (existing != null) return existing;
    final created = _directoryProvider().then((directory) async {
      if (!await directory.exists()) await directory.create(recursive: true);
      return directory;
    });
    _directoryFuture = created;
    try {
      return await created;
    } catch (_) {
      if (identical(_directoryFuture, created)) _directoryFuture = null;
      rethrow;
    }
  }

  Future<String> copyIntoManagedStorage(String sourcePath) async {
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw FileSystemException('Selected photo does not exist.', sourcePath);
    }
    final directory = await _directory();
    final extension = _safeExtension(source.uri.pathSegments.last);
    File destination;
    do {
      final name =
          '${DateTime.now().microsecondsSinceEpoch}_${_sequence++}$extension';
      destination = File('${directory.path}${Platform.pathSeparator}$name');
    } while (await destination.exists());
    return (await source.copy(destination.path)).path;
  }

  Future<void> deleteIfManaged(String? path) async {
    if (path == null || path.trim().isEmpty) return;
    final file = File(path);
    if (!await file.exists()) return;
    final directory = await _directory();
    final directoryPath = await directory.resolveSymbolicLinks();
    final filePath = await file.resolveSymbolicLinks();
    if (!_isWithin(directoryPath, filePath)) return;
    await file.delete();
  }

  bool _isWithin(String directoryPath, String filePath) {
    final separator = Platform.pathSeparator;
    final directory = Platform.isWindows
        ? directoryPath.toLowerCase()
        : directoryPath;
    final file = Platform.isWindows ? filePath.toLowerCase() : filePath;
    return file.startsWith('$directory$separator');
  }

  String _safeExtension(String fileName) {
    final dot = fileName.lastIndexOf('.');
    if (dot <= 0 || dot == fileName.length - 1) return '';
    final extension = fileName.substring(dot).toLowerCase();
    return RegExp(r'^\.[a-z0-9]{1,10}$').hasMatch(extension) ? extension : '';
  }
}
