import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// Manages local caching of schema structures
class SchemaCacheManager {
  static const String _cachePrefix = 'dynamic_schema_cache_';
  static const String _timestampSuffix = '_timestamp';

  final String namespace;
  final Duration? cacheDuration;

  SchemaCacheManager({
    required this.namespace,
    this.cacheDuration = const Duration(days: 7),
  });

  // Save a schema to cache
  Future<void> saveSchema(String key, Map<String, dynamic> schema) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getCacheKey(key);
      final timestampKey = _getTimestampKey(key);

      final schemaJson = jsonEncode(schema);
      await prefs.setString(cacheKey, schemaJson);
      await prefs.setInt(timestampKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      // Silent fail - caching is optional functionality
      // In production, you might want to log this to an error tracking service
    }
  }

  // Load a schema from cache
  Future<Map<String, dynamic>?> loadSchema(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getCacheKey(key);
      final timestampKey = _getTimestampKey(key);

      final schemaJson = prefs.getString(cacheKey);
      if (schemaJson == null) return null;

      // Check if cache has expired
      if (cacheDuration != null) {
        final timestamp = prefs.getInt(timestampKey);
        if (timestamp != null) {
          final cacheDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
          if (DateTime.now().difference(cacheDate) > cacheDuration!) {
            // Cache expired, remove it
            await clearSchema(key);
            return null;
          }
        }
      }

      return jsonDecode(schemaJson) as Map<String, dynamic>;
    } catch (e) {
      // Silent fail - return null if cache can't be loaded
      return null;
    }
  }

  // Clear a specific schema from cache
  Future<void> clearSchema(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_getCacheKey(key));
      await prefs.remove(_getTimestampKey(key));
    } catch (e) {
      // Silent fail
    }
  }

  // Clear all schemas in this namespace
  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final prefix = '$_cachePrefix$namespace';

      for (final key in keys) {
        if (key.startsWith(prefix)) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      // Silent fail
    }
  }

  // Get all cached schema keys in this namespace
  Future<List<String>> getCachedKeys() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final prefix = '$_cachePrefix${namespace}_';

      return keys
          .where(
            (key) => key.startsWith(prefix) && !key.endsWith(_timestampSuffix),
          )
          .map((key) => key.substring(prefix.length))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Check if a schema exists in cache and is valid
  Future<bool> hasValidCache(String key) async {
    final schema = await loadSchema(key);
    return schema != null;
  }

  // Get cache metadata (timestamp, size, etc.)
  Future<CacheMetadata?> getCacheMetadata(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getCacheKey(key);
      final timestampKey = _getTimestampKey(key);

      final schemaJson = prefs.getString(cacheKey);
      if (schemaJson == null) return null;

      final timestamp = prefs.getInt(timestampKey);
      final cacheDate = timestamp != null
          ? DateTime.fromMillisecondsSinceEpoch(timestamp)
          : null;

      final isExpired =
          cacheDuration != null &&
          cacheDate != null &&
          DateTime.now().difference(cacheDate) > cacheDuration!;

      return CacheMetadata(
        key: key,
        cachedAt: cacheDate,
        sizeBytes: schemaJson.length,
        isExpired: isExpired,
      );
    } catch (e) {
      return null;
    }
  }

  String _getCacheKey(String key) => '$_cachePrefix${namespace}_$key';
  String _getTimestampKey(String key) =>
      '${_getCacheKey(key)}$_timestampSuffix';
}

// Metadata about a cached schema
class CacheMetadata {
  final String key;
  final DateTime? cachedAt;
  final int sizeBytes;
  final bool isExpired;

  CacheMetadata({
    required this.key,
    this.cachedAt,
    required this.sizeBytes,
    required this.isExpired,
  });

  String get sizeFormatted {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  String toString() {
    return 'CacheMetadata(key: $key, cachedAt: $cachedAt, size: $sizeFormatted, expired: $isExpired)';
  }
}

// Example usage:
//
// ```dart
// final cacheManager = SchemaCacheManager(
//   namespace: 'my_app',
//   cacheDuration: Duration(hours: 24),
// );
//
// // Save schema
// await cacheManager.saveSchema('users', schema.getSchemaStructure());
//
// // Load schema
// final cachedSchema = await cacheManager.loadSchema('users');
//
// // Check if valid cache exists
// if (await cacheManager.hasValidCache('users')) {
//   print('Using cached schema');
// }
// ```
