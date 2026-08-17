import 'package:dio/dio.dart';
import 'package:local_basket/core/constants/global_exception_handler.dart';
import 'package:local_basket/core/constants/api_constants.dart';
import 'package:local_basket/data/model/authentication/rolesPost_model.dart';

abstract class RolePostRemoteDatasource {
  Future<RolePostModel> RolePost({
    String? role,
  });
}

class RolePostRemoteDataSourceImpl implements RolePostRemoteDatasource {
  final Dio client;

  RolePostRemoteDataSourceImpl({required this.client});

  @override
  Future<RolePostModel> RolePost({
    String? role,
  }) async {
    try {
      print('Role: $role');

      final response = await client.request(
        '$baseUrl2$rolePostUrl/role/$role',
        options: Options(method: 'PUT'),
      );

      print('Response: ${response.data}');

      if (response.statusCode == 200) {
        return RolePostModel.fromJson(response.data);
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
