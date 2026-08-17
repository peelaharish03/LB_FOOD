import 'package:dio/dio.dart';
import 'package:local_basket/core/constants/global_exception_handler.dart';
import 'package:local_basket/core/constants/api_constants.dart';
import 'package:local_basket/data/model/cart/getCart/getCart_model.dart';


abstract class GetCartRemoteDataSource {
  Future<GetCartModel> getCart();
}

class GetCartRemoteDataSourceImpl
    implements GetCartRemoteDataSource {
  final Dio client;

  GetCartRemoteDataSourceImpl({required this.client});

  @override
  Future<GetCartModel> getCart() async {
    try {
      final response = await client.request(
        '$baseUrl${getCartUrl()}',
        options: Options(method: 'GET'),
      );
      if (response.statusCode == 200) {
        print('responce of GetCart:: $response');
        return GetCartModel.fromJson(response.data);
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
