import 'dart:io';

import 'package:data_repository/utils/api_config.dart';
import 'package:path_provider/path_provider.dart';

/// Cache manager class that handles all the cache operations
class CacheManager {
  /// Subdirectory of the temporary directory that entries are written to.
  final String directoryName;

  CacheManager({this.directoryName = 'data_repository_cache'});

  Directory? _directory;

  Future<Directory> _resolveDirectory() async {
    final existing = _directory;
    if (existing != null) return existing;
    final temp = await getTemporaryDirectory();
    final dir = Directory('${temp.path}/$directoryName');
    if (!await dir.exists()) await dir.create(recursive: true);
    return _directory = dir;
  }

  /// Maps a cache key to a filename.
  ///
  /// The key is reduced to safe characters plus a hash of the whole key: it
  /// may contain slashes, query strings or characters the filesystem rejects,
  /// and taking the last path segment (as this once did) collided distinct
  /// keys such as `posts/1` and `comments/1` onto the same file. The readable
  /// prefix is kept only to make the cache directory browsable.
  String fileNameFor(String key) {
    final safe = key
        .replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    final prefix = safe.length <= 40 ? safe : safe.substring(0, 40);
    return '${prefix}_${_hash(key)}.json';
  }

  /// FNV-1a, used purely to disambiguate filenames — not for security.
  String _hash(String value) {
    var hash = 0x811c9dc5;
    for (final unit in value.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  Future<File> _fileFor(String key) async =>
      File('${(await _resolveDirectory()).path}/${fileNameFor(key)}');

  /// returns data stored in the cache for the given key
  Future<String?> getCachedData(String key) async {
    try {
      final file = await _fileFor(key);
      if (!await file.exists()) return null;
      return await file.readAsString();
    } catch (e) {
      ApiConfig().log('cache read failed for $key: $e');
      return null;
    }
  }

  /// stores data in the cache for the given key
  Future<bool> saveToCache(String key, String data) async {
    try {
      await (await _fileFor(key)).writeAsString(data);
      return true;
    } catch (e) {
      ApiConfig().log('cache write failed for $key: $e');
      return false;
    }
  }

  /// removes the entry for [key], if any
  Future<void> remove(String key) async {
    try {
      final file = await _fileFor(key);
      if (await file.exists()) await file.delete();
    } catch (e) {
      ApiConfig().log('cache delete failed for $key: $e');
    }
  }

  /// removes every entry this manager owns
  Future<void> clear() async {
    try {
      final dir = await _resolveDirectory();
      if (await dir.exists()) await dir.delete(recursive: true);
      _directory = null;
    } catch (e) {
      ApiConfig().log('cache clear failed: $e');
    }
  }
}
