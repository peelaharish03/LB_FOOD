import 'package:dio/dio.dart';
import 'package:local_basket/core/constants/global_exception_handler.dart';
import 'package:local_basket/core/constants/api_constants.dart';
import 'package:local_basket/data/model/orders/reOrder/reOrder_model.dart';

abstract class ReOrderRemoteDataSource {
  Future<ReOrderModel> reOrder(
    dynamic payload,
  );
}

class ReOrderRemoteDataSourceImpl implements ReOrderRemoteDataSource {
  final Dio client;

  ReOrderRemoteDataSourceImpl({required this.client});

  @override
  Future<ReOrderModel> reOrder(
    dynamic payload,
  ) async {
    print(payload);
    try {
      final response = await client.post(
        '$baseUrl$reOrderUrl',
        data: payload,
      );

      print('ReOrder Response: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ReOrderModel.fromJson(response.data);
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
