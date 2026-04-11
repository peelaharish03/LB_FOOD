import 'package:local_basket/core/utils/cache_service.dart';

/// Repository-level cache that persists data across screen navigation
/// This prevents re-fetching data when navigating between screens
class RepositoryCache {
  static final RepositoryCache _instance = RepositoryCache._internal();
  factory RepositoryCache() => _instance;
  RepositoryCache._internal();

  final CacheService _cacheService = CacheService();
  
  // In-memory cache for instant access
  final Map<String, dynamic> _memoryCache = {};
  final Map<String, DateTime> _memoryCacheTimestamps = {};
  
  /// Store data in both memory and persistent cache
  Future<void> setData(String key, dynamic data, {Duration? ttl}) async {
    final effectiveTtl = ttl ?? const Duration(minutes: 30);
    
    // Store in memory for instant access
    _memoryCache[key] = data;
    _memoryCacheTimestamps[key] = DateTime.now().add(effectiveTtl);
    
    // Store in persistent cache
    await _cacheService.setCacheData(key, data, durationMinutes: effectiveTtl.inMinutes);
    
    print('💾 RepositoryCache: Stored data for key: $key (TTL: ${effectiveTtl.inMinutes}min)');
  }
  
  /// Get data from memory cache first, then persistent cache
  Future<T?> getData<T>(String key, T Function(dynamic) fromJson) async {
    // Check memory cache first
    if (_memoryCache.containsKey(key)) {
      final timestamp = _memoryCacheTimestamps[key];
      if (timestamp != null && DateTime.now().isBefore(timestamp)) {
        print('⚡ RepositoryCache: Hit memory cache for key: $key');
        return _memoryCache[key] as T?;
      } else {
        // Remove expired memory cache
        _memoryCache.remove(key);
        _memoryCacheTimestamps.remove(key);
        print('⏰ RepositoryCache: Memory cache expired for key: $key');
      }
    }
    
    // Check persistent cache
    final cachedData = await _cacheService.getCachedData<Map<String, dynamic>>(
      key,
      (json) => json as Map<String, dynamic>,
    );
    
    if (cachedData != null) {
      // Restore to memory cache
      final data = fromJson(cachedData);
      _memoryCache[key] = data;
      _memoryCacheTimestamps[key] = DateTime.now().add(const Duration(minutes: 30));
      
      print('💾 RepositoryCache: Restored from persistent cache for key: $key');
      return data as T?;
    }
    
    print('❌ RepositoryCache: No data found for key: $key');
    return null;
  }
  
  /// Check if data exists in cache
  Future<bool> hasData(String key) async {
    // Check memory cache
    if (_memoryCache.containsKey(key)) {
      final timestamp = _memoryCacheTimestamps[key];
      if (timestamp != null && DateTime.now().isBefore(timestamp)) {
        return true;
      }
    }
    
    // Check persistent cache
    return await _cacheService.isCacheValid(key);
  }
  
  /// Clear cached data
  Future<void> clearData(String key) async {
    _memoryCache.remove(key);
    _memoryCacheTimestamps.remove(key);
    await _cacheService.clearCache(key);
    print('🗑️ RepositoryCache: Cleared data for key: $key');
  }
  
  /// Clear all cached data
  Future<void> clearAll() async {
    _memoryCache.clear();
    _memoryCacheTimestamps.clear();
    await _cacheService.clearAllCache();
    print('🗑️ RepositoryCache: Cleared all data');
  }
  
  /// Force refresh by clearing specific key
  Future<void> refresh(String key) async {
    await clearData(key);
    print('🔄 RepositoryCache: Refresh requested for key: $key');
  }
}
