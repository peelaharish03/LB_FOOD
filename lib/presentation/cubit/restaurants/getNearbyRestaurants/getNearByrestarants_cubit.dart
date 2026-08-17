
import 'package:local_basket/core/data/repository_cache.dart';
import 'package:local_basket/core/constants/global_exception_handler.dart';
import 'package:local_basket/data/model/restaurants/getNearbyRestaurants/getNearByrestarants_model.dart';
import 'package:local_basket/domain/usecase/restaurants/getNearbyRestaurants/getNearByrestarants_usecase.dart';
import 'package:local_basket/presentation/cubit/restaurants/getNearbyRestaurants/getNearByrestarants_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GetNearbyRestaurantsCubit extends Cubit<GetNearbyRestaurantsState> {
  final GetNearByRestaurantsUseCase getNearbyRestaurantsUseCase;
  final RepositoryCache _repositoryCache = RepositoryCache();

  GetNearbyRestaurantsCubit({required this.getNearbyRestaurantsUseCase})
      : super(GetNearbyRestaurantsInitial());

  Future<void> fetchNearbyRestaurants(Map<String, dynamic> params, {bool forceRefresh = false}) async {
    // Generate cache key based on parameters
    final cacheKey = _generateCacheKey(params);
    print('🚀 fetchNearbyRestaurants called with cacheKey: $cacheKey, forceRefresh: $forceRefresh');
    
    // Try to get cached data first (unless force refresh)
    if (!forceRefresh) {
      print('🔍 Checking repository cache for restaurants data...');
      final cachedData = await _repositoryCache.getData<GetNearByStoresModel>(
        cacheKey,
        (json) => GetNearByStoresModel.fromJson(json),
      );
      
      if (cachedData != null) {
        print('📦 Using repository cached restaurants data - found ${cachedData.content.length} restaurants');
        emit(GetNearbyRestaurantsLoaded(cachedData));
        return;
      } else {
        print('❌ No valid cached data found, fetching from API');
      }
    } else {
      // Clear cache for this specific request
      await _repositoryCache.refresh(cacheKey);
      print('🔄 Force refreshing restaurants data');
    }

    // Fetch from API if no cached data or force refresh
    print('🌐 Fetching restaurants from API...');
    emit(GetNearbyRestaurantsLoading());
    try {
      final result = await getNearbyRestaurantsUseCase(params);
      print('✅ API returned ${result.content.length} restaurants');
      
      // Cache the result for future use (30 minutes)
      print('💾 Caching restaurants data in repository for 30 minutes...');
      await _repositoryCache.setData(cacheKey, result, ttl: const Duration(minutes: 30));
      
      emit(GetNearbyRestaurantsLoaded(result));
    } catch (e) {
      print('❌ Error fetching restaurants: $e');
      emit(GetNearbyRestaurantsError(friendlyErrorMessage(e)));
    }
  }

  /// Silently re-fetches nearby stores in the background (e.g. on a timer)
  /// to pick up active/inactive status changes, without flashing a loading
  /// state and without surfacing a transient network failure as an error —
  /// the last good list just stays on screen until the next successful poll.
  Future<void> pollNearbyRestaurants(Map<String, dynamic> params) async {
    final cacheKey = _generateCacheKey(params);
    try {
      final result = await getNearbyRestaurantsUseCase(params);
      await _repositoryCache.setData(cacheKey, result, ttl: const Duration(minutes: 30));
      emit(GetNearbyRestaurantsLoaded(result));
    } catch (e) {
      print('⚠️ Background store status poll failed: $e');
    }
  }

  /// Generate unique cache key based on request parameters
  String _generateCacheKey(Map<String, dynamic> params) {
    final keyParts = <String>[];
    params.forEach((key, value) {
      if (value != null) {
        keyParts.add('$key=$value');
      }
    });
    return 'nearby_restaurants_${keyParts.join('_')}';
  }

  /// Force refresh restaurants data
  Future<void> refreshRestaurants(Map<String, dynamic> params) async {
    await fetchNearbyRestaurants(params, forceRefresh: true);
  }

  /// Clear all restaurant cache
  Future<void> clearRestaurantCache() async {
    await _repositoryCache.clearData('nearby_restaurants');
  }
}
