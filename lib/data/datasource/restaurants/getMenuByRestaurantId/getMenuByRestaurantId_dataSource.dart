
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:local_basket/core/constants/api_constants.dart';
import 'package:local_basket/data/model/restaurants/getMenuByRestaurantId/getMenuByRestaurantId_model.dart';

abstract class GetMenuByRestaurantIdRemoteDataSource {
  Future<GetMenuByRestaurantIdModel> getMenuByRestaurantId(Map<String, dynamic> params);
}


class GetMenuByRestaurantIdRemoteDataSourceImpl
    implements GetMenuByRestaurantIdRemoteDataSource {
  final Dio client;

  GetMenuByRestaurantIdRemoteDataSourceImpl({required this.client});

  @override
  Future<GetMenuByRestaurantIdModel> getMenuByRestaurantId(Map<String, dynamic> params) async {
    try {
      final String storeId = params['restaurantId'];
      final String b2bUnitId = params['b2bUnitId'];
      final int page = params['page'] ?? 0;
      final int size = params['size'] ?? 20;

      final url = '$baseUrl${getMenuByRestaurantIdUrl(storeId, b2bUnitId, page, size)}';

      final response = await client.request(
        url,
        options: Options(method: 'GET'),
      );

      if (response.statusCode == 200) {
        final body = response.data;
        print('📦 GET $url');
        print(
          '✅ GetMenuByRestaurantId response (status ${response.statusCode}): ${jsonEncode(body)}',
        );
        return GetMenuByRestaurantIdModel.fromJson(response.data);
      } else {
        throw Exception(
            'Failed to load GetMenuByRestaurantId data: ${response.statusCode}');
      }
    } catch (e) {
      print(e);
      throw Exception('Failed to load GetMenuByRestaurantId data: ${e.toString()}');
    }
  }
}
