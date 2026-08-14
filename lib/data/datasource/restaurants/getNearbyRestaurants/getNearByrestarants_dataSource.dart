import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:local_basket/core/constants/api_constants.dart';
import 'package:local_basket/data/model/restaurants/getNearbyRestaurants/getNearByrestarants_model.dart';

abstract class GetNearByRestaurantsRemoteDataSource {
  Future<GetNearByStoresModel> getNearByRestaurants(
    Map<String, dynamic> params,
  );
}

class GetNearByRestaurantsRemoteDataSourceImpl
    implements GetNearByRestaurantsRemoteDataSource {
  final Dio client;

  GetNearByRestaurantsRemoteDataSourceImpl({required this.client});

  @override
  Future<GetNearByStoresModel> getNearByRestaurants(
    Map<String, dynamic> params,
  ) async {
    try {
      final double latitude = (params['latitude'] as num).toDouble();
      final double longitude = (params['longitude'] as num).toDouble();
      final double radius = ((params['radius'] ?? 5) as num).toDouble();
      final int page = params['page'] ?? 0;
      final int size = params['size'] ?? 20;

      final url =
          '$baseUrl2${getNearbyRestaurantsUrl(latitude, longitude, radius, page, size)}';

      final response = await client.request(
        url,
        options: Options(method: 'GET'),
      );

      if (response.statusCode == 200) {
        final body = response.data;
        print('📦 GET $url');
        print(
          '✅ getNearByRestaurants response (status ${response.statusCode}): ${jsonEncode(body)}',
        );
        print('data:  ${response.data}');
        return GetNearByStoresModel.fromJson(response.data);
      } else {
        throw Exception(
          'Failed to load getNearByRestaurants data: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception(
        'Failed to load getNearByRestaurants data: ${e.toString()}',
      );
    }
  }
}
