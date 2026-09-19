
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

  /// Silently re-fetches nearby stores in the background (e.g. on a timer or
  /// as the user travels) to pick up active/inactive status changes and new
  /// stores coming into range, without flashing a loading state and without
  /// surfacing a transient network failure as an error — the last good list
  /// just stays on screen until the next successful poll.
  ///
  /// Only emits when the result actually differs from what's on screen, so a
  /// poll that returns the same stores (the common case) never triggers a
  /// list rebuild in the UI.
  Future<void> pollNearbyRestaurants(Map<String, dynamic> params) async {
    final cacheKey = _generateCacheKey(params);
    try {
      final result = await getNearbyRestaurantsUseCase(params);
      await _repositoryCache.setData(cacheKey, result, ttl: const Duration(minutes: 30));

      final currentState = state;
      if (currentState is GetNearbyRestaurantsLoaded &&
          _sameStores(currentState.model.content, result.content)) {
        return;
      }

      emit(GetNearbyRestaurantsLoaded(result));
    } catch (e) {
      print('⚠️ Background store status poll failed: $e');
    }
  }

  /// Compares two store lists on the fields that actually matter to the UI
  /// (identity, order, active status, distance) so GPS jitter — which nudges
  /// distanceKm by a few meters on every poll — doesn't register as a change.
  bool _sameStores(List<StoreContent> a, List<StoreContent> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id ||
          a[i].active != b[i].active ||
          _roundedKm(a[i].distanceKm) != _roundedKm(b[i].distanceKm)) {
        return false;
      }
    }
    return true;
  }

  // Rounds to the nearest 100m so small GPS drift doesn't count as a change.
  double? _roundedKm(double? km) => km == null ? null : (km * 10).round() / 10;

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
