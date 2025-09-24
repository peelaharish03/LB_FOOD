import 'package:dio/dio.dart';
import 'package:local_basket/core/constants/api_constants.dart';
import 'package:local_basket/data/model/offers/restaurant_offers/restaurant_offers_model.dart';

abstract class RestaurantOffersRemoteDataSource {
  Future<RestaurantOffersModel> restaurantOffers();
}

class RestaurantOffersRemoteDataSourceImpl implements RestaurantOffersRemoteDataSource {
  final Dio client;

  RestaurantOffersRemoteDataSourceImpl({required this.client});

  @override
  Future<RestaurantOffersModel> restaurantOffers() async {
    try {
      final response = await client.request(
        '$baseUrl$restaurantOffersUrl',
        options: Options(method: 'GET'),
      );
      if (response.statusCode == 200) {
        print('responce of RestaurantOffers:: $response');
        return RestaurantOffersModel.fromJson(response.data);
      } else {
        throw Exception('Failed to load RestaurantOffers data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load RestaurantOffers data: ${e.toString()}');
    }
  }
}
