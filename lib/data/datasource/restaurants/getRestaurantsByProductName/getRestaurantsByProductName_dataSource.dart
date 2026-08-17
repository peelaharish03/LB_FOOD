import 'package:dio/dio.dart';
import 'package:local_basket/core/constants/global_exception_handler.dart';
import 'package:local_basket/core/constants/api_constants.dart';
import 'package:local_basket/data/model/restaurants/getRestaurantsByProductName/getRestaurantsByProductName_model.dart';

abstract class GetRestaurantsByProductNameRemoteDataSource {
  Future<GetRestaurantsByProductNameModel> getRestaurantsByProductName(
    Map<String, dynamic> params,
  );
}

class GetRestaurantsByProductNameRemoteDataSourceImpl
    implements GetRestaurantsByProductNameRemoteDataSource {
  final Dio client;

  GetRestaurantsByProductNameRemoteDataSourceImpl({required this.client});

  @override
  Future<GetRestaurantsByProductNameModel> getRestaurantsByProductName(
    Map<String, dynamic> params,
  ) async {
    try {
      final String productName = params['productName'] ?? '';
      final double latitude = (params['latitude'] as num).toDouble();
      final double longitude = (params['longitude'] as num).toDouble();
      final double radius = ((params['radius'] ?? 5) as num).toDouble();
      final int page = params['page'] ?? 0;
      final int size = params['size'] ?? 20;
      final url =
          '$baseUrl2${getRestaurantsByProductNameUrl(productName, latitude, longitude, radius, page, size)}';

      final response = await client.request(
        url,
        options: Options(method: 'GET'),
      );

      if (response.statusCode == 200) {
        print('response of GetRestaurantsByProductName:: $response');
        return GetRestaurantsByProductNameModel.fromJson(response.data);
      } else {
        throw UnknownBackendException("Unable to complete this request. Please try again after some time.");
      }
    } on DioException catch (e) {
      throw handleDioError(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownBackendException("Unable to complete this request. Please try again after some time.");
    }
  }
}
