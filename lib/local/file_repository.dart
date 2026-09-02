import 'dart:async';
import 'dart:convert';

import 'package:data_repository/cache/cache_manager.dart';
import 'package:data_repository/utils/api_config.dart';

import 'local_repository.dart';

/// A [LocalRepository] that persists to the device's temporary directory.
///
/// This is the batteries-included implementation: it survives app restarts and
/// needs no third-party storage package, so caching works without writing an
/// adapter first.
///
/// ```dart
/// GetIt.I.registerSingleton<LocalRepository>(FileLocalRepository());
/// ```
///
/// Swap it for [MapRepository] in tests, or supply your own implementation
/// backed by Hive, Isar or shared_preferences — nothing above the
/// [LocalRepository] interface changes.
class FileLocalRepository implements LocalRepository {
  final CacheManager _cacheManager;

  /// Expiry timestamps, kept in memory and rehydrated lazily from disk so a
  /// cold start does not have to scan every entry.
  final Map<String, int> _expiryCache = {};

  FileLocalRepository({CacheManager? cacheManager})
    : _cacheManager = cacheManager ?? CacheManager();

  @override
  bool isInitialized = false;

  @override
  Future init() async => isInitialized = true;

  /// Entries are stored as a single envelope per key so that the payload and
  /// its expiry cannot drift apart.
  Map<String, dynamic> _envelope(String data, int? expiresAt) => {
    'expiresAt': expiresAt,
    'data': data,
  };

  Future<Map<String, dynamic>?> _read(String key) async {
    final raw = await _cacheManager.getCachedData(key);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (e) {
      ApiConfig().log('discarding corrupt cache entry $key: $e');
      return null;
    }
  }

  @override
  Future<dynamic> getData(String key) async =>
      (await _read(key))?['data'] as String?;

  @override
  Future<dynamic> saveData(String key, String data) async {
    final expiresAt = _expiryCache[key] ?? (await _read(key))?['expiresAt'];
    return _cacheManager.saveToCache(
      key,
      jsonEncode(_envelope(data, expiresAt as int?)),
    );
  }

  @override
  void saveTime(String key, int duration) {
    if (key.isEmpty) return;
    _expiryCache[key] = duration;
    // Rewrite the envelope so the expiry survives a restart.
    unawaited(_persistExpiry(key, duration));
  }

  Future<void> _persistExpiry(String key, int expiresAt) async {
    final existing = await _read(key);
    if (existing == null) return;
    await _cacheManager.saveToCache(
      key,
      jsonEncode(_envelope(existing['data'] as String? ?? '', expiresAt)),
    );
  }

  @override
  Future<int?> getTime(String key) async {
    final cached = _expiryCache[key];
    if (cached != null) return cached;
    final expiresAt = (await _read(key))?['expiresAt'];
    if (expiresAt is int) return _expiryCache[key] = expiresAt;
    return null;
  }

  @override
  Future<bool> checkCache(String key) async {
    final expiresAt = await getTime(key);
    if (expiresAt == null) return false;
    return DateTime.now().millisecondsSinceEpoch < expiresAt;
  }

  @override
  void clearCache() {
    _expiryCache.clear();
    unawaited(_cacheManager.clear());
  }

  @override
  void removeData(String key) {
    _expiryCache.remove(key);
    unawaited(_cacheManager.remove(key));
  }
}
