
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
      final String restaurantId = params['restaurantId'];
      final String search = params['search'];
      final int page = params['page'];
      final int size = params['size'];

      final url = '$baseUrl${getMenuByRestaurantIdUrl(restaurantId, search, page, size)}';

      final response = await client.request(
        url,
        options: Options(method: 'GET'),
      );

      if (response.statusCode == 200) {
        print('response of GetMenuByRestaurantId:: $response');
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
