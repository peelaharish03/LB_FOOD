import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const String _cachePrefix = 'cache_';
  static const String _timestampPrefix = 'timestamp_';
  
  // Cache duration in minutes (default: 30 minutes)
  static const int _defaultCacheDuration = 30;

  /// Store data in cache with timestamp
  Future<void> setCacheData(String key, dynamic data, {int? durationMinutes}) async {
    try {
      final cacheKey = _cachePrefix + key;
      final timestampKey = _timestampPrefix + key;
      final duration = durationMinutes ?? _defaultCacheDuration;
      
      // Store the actual data
      final jsonString = jsonEncode(data);
      await _secureStorage.write(key: cacheKey, value: jsonString);
      
      // Store timestamp with expiry
      final expiryTime = DateTime.now().add(Duration(minutes: duration)).millisecondsSinceEpoch;
      await _secureStorage.write(key: timestampKey, value: expiryTime.toString());
      
      print('📦 Cached data for key: $key (expires in ${duration}min)');
    } catch (e) {
      print('❌ Error caching data for $key: $e');
    }
  }

  /// Get data from cache if not expired
  Future<T?> getCachedData<T>(String key, T Function(dynamic) fromJson) async {
    try {
      final cacheKey = _cachePrefix + key;
      final timestampKey = _timestampPrefix + key;
      
      print('🔍 Looking for cache key: $cacheKey');
      
      // Check if data exists
      final cachedData = await _secureStorage.read(key: cacheKey);
      if (cachedData == null) {
        print('📭 No cached data found for key: $key');
        return null;
      }
      
      print('✅ Found cached data for key: $key, length: ${cachedData.length}');
      
      // Check if cache is expired
      final expiryTimestamp = await _secureStorage.read(key: timestampKey);
      if (expiryTimestamp != null) {
        final expiryTime = int.parse(expiryTimestamp);
        final currentTime = DateTime.now().millisecondsSinceEpoch;
        
        if (currentTime > expiryTime) {
          print('⏰ Cache expired for key: $key (expired at $expiryTime, current time $currentTime)');
          await clearCache(key);
          return null;
        } else {
          print('✅ Cache still valid for key: $key (expires at $expiryTime, current time $currentTime)');
        }
      }
      
      // Parse and return cached data
      final jsonData = jsonDecode(cachedData);
      final result = fromJson(jsonData);
      print('🎉 Successfully retrieved and parsed cached data for key: $key');
      return result;
    } catch (e) {
      print('❌ Error retrieving cached data for $key: $e');
      return null;
    }
  }

  /// Clear specific cache entry
  Future<void> clearCache(String key) async {
    try {
      final cacheKey = _cachePrefix + key;
      final timestampKey = _timestampPrefix + key;
      
      await _secureStorage.delete(key: cacheKey);
      await _secureStorage.delete(key: timestampKey);
      
      print('🗑️ Cleared cache for key: $key');
    } catch (e) {
      print('❌ Error clearing cache for $key: $e');
    }
  }

  /// Clear all cached data
  Future<void> clearAllCache() async {
    try {
      final allData = await _secureStorage.readAll();
      final keysToDelete = <String>[];
      
      for (final key in allData.keys) {
        if (key.startsWith(_cachePrefix) || key.startsWith(_timestampPrefix)) {
          keysToDelete.add(key);
        }
      }
      
      for (final key in keysToDelete) {
        await _secureStorage.delete(key: key);
      }
      
      print('🗑️ Cleared all cached data (${keysToDelete.length} entries)');
    } catch (e) {
      print('❌ Error clearing all cache: $e');
    }
  }

  /// Check if cache exists and is valid
  Future<bool> isCacheValid(String key) async {
    try {
      final timestampKey = _timestampPrefix + key;
      final expiryTimestamp = await _secureStorage.read(key: timestampKey);
      
      if (expiryTimestamp == null) return false;
      
      final expiryTime = int.parse(expiryTimestamp);
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      
      return currentTime <= expiryTime;
    } catch (e) {
      print('❌ Error checking cache validity for $key: $e');
      return false;
    }
  }

  /// Force refresh by clearing cache for specific key
  Future<void> refreshCache(String key) async {
    await clearCache(key);
    print('🔄 Cache refresh requested for key: $key');
  }
}
