import 'package:dio/dio.dart';
import 'package:local_basket/core/constants/global_exception_handler.dart';
import 'package:local_basket/core/constants/api_constants.dart';
import 'package:local_basket/data/model/offers/promotions/promotions_model.dart';

abstract class PromotionsRemoteDataSource {
  Future<PromotionsModel> getPromotions();
}

class PromotionsRemoteDataSourceImpl implements PromotionsRemoteDataSource {
  final Dio client;

  PromotionsRemoteDataSourceImpl({required this.client});

  @override
  Future<PromotionsModel> getPromotions() async {
    try {
      final response = await client.request(
        '$baseUrl$promotionsUrl',
        options: Options(method: 'GET'),
      );
      if (response.statusCode == 200) {
        print('response of Promotions:: $response');
        final data = response.data;
        if (data is List) {
          return PromotionsModel.fromJson({'content': data});
        }
        return PromotionsModel.fromJson(data);
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
