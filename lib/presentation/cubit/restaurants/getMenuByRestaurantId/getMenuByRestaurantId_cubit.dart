import 'package:local_basket/core/utils/cache_service.dart';
import 'package:local_basket/core/constants/global_exception_handler.dart';
import 'package:local_basket/data/model/restaurants/getMenuByRestaurantId/getMenuByRestaurantId_model.dart';
import 'package:local_basket/domain/usecase/restaurants/getMenuByRestaurantId/getMenuByRestaurantId_usecase.dart';
import 'package:local_basket/presentation/cubit/restaurants/getMenuByRestaurantId/getMenuByRestaurantId_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GetMenuByRestaurantIdCubit extends Cubit<GetMenuByRestaurantIdState> {
  final GetMenuByRestaurantIdUseCase useCase;
  final CacheService _cacheService = CacheService();

  GetMenuByRestaurantIdCubit(this.useCase) : super(GetMenuByRestaurantIdInitial());

  Future<void> fetchMenu(Map<String, dynamic> params, {bool forceRefresh = false}) async {
    print(params);
    
    // Generate cache key based on restaurant ID and parameters
    final cacheKey = _generateCacheKey(params);
    
    // Try to get cached data first (unless force refresh)
    if (!forceRefresh) {
      final cachedData = await _cacheService.getCachedData<Map<String, dynamic>>(
        cacheKey,
        (json) => json as Map<String, dynamic>,
      );
      
      if (cachedData != null) {
        print('📦 Using cached menu data for restaurant');
        final model = GetMenuByRestaurantIdModel.fromJson(cachedData);
        emit(GetMenuByRestaurantIdLoaded(model));
        return;
      }
    } else {
      // Clear cache for this specific request
      await _cacheService.clearCache(cacheKey);
      print('🔄 Force refreshing menu data for restaurant');
    }

    // Fetch from API if no cached data or force refresh
    emit(GetMenuByRestaurantIdLoading());
    try {
      final result = await useCase(params);
      print('📦 Menu data fetched (caching disabled for this model)');
      
      emit(GetMenuByRestaurantIdLoaded(result));
    } catch (e) {
      emit(GetMenuByRestaurantIdError(friendlyErrorMessage(e)));
    }
  }

  /// Generate unique cache key based on restaurant ID and parameters
  String _generateCacheKey(Map<String, dynamic> params) {
    final keyParts = <String>[];
    params.forEach((key, value) {
      if (value != null) {
        keyParts.add('$key=$value');
      }
    });
    return 'restaurant_menu_${keyParts.join('_')}';
  }

  /// Force refresh menu data
  Future<void> refreshMenu(Map<String, dynamic> params) async {
    await fetchMenu(params, forceRefresh: true);
  }

  /// Clear menu cache for specific restaurant
  Future<void> clearMenuCache(String restaurantId) async {
    await _cacheService.clearCache('restaurant_menu_restaurantId=$restaurantId');
  }
}
