import 'package:dio/dio.dart';
import 'package:local_basket/core/constants/global_exception_handler.dart';
import 'package:local_basket/core/constants/api_constants.dart';
import 'package:local_basket/data/model/pools/joinPool/joinPool_model.dart';

abstract class JoinPoolRemoteDataSource {
  Future<JoinPoolModel> joinPool(String poolId);
}

class JoinPoolRemoteDataSourceImpl implements JoinPoolRemoteDataSource {
  final Dio client;

  JoinPoolRemoteDataSourceImpl({required this.client});

  @override
  Future<JoinPoolModel> joinPool(String poolId) async {
    try {
      final url = '$baseUrl${joinPoolUrl(defaultB2bUnitId, poolId)}';
      final response = await client.request(
        url,
        options: Options(method: 'POST'),
      );
      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 204) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          return JoinPoolModel.fromJson(data);
        }
        return JoinPoolModel(success: true);
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
