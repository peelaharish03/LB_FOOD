import 'package:dio/dio.dart';
import 'package:local_basket/core/constants/global_exception_handler.dart';
import 'package:local_basket/core/constants/api_constants.dart';
import 'package:local_basket/data/model/pools/pools_model.dart';

abstract class GetPoolsRemoteDataSource {
  Future<PoolsModel> getPools();
}

class GetPoolsRemoteDataSourceImpl implements GetPoolsRemoteDataSource {
  final Dio client;

  GetPoolsRemoteDataSourceImpl({required this.client});

  @override
  Future<PoolsModel> getPools() async {
    try {
      final url = '$baseUrl${getPoolsUrl(defaultB2bUnitId)}';
      final response = await client.request(
        url,
        options: Options(method: 'GET'),
      );
      if (response.statusCode == 200) {
        return PoolsModel.fromJson(response.data);
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
