import 'package:dio/dio.dart';
import 'package:local_basket/core/constants/global_exception_handler.dart';
import 'package:local_basket/core/constants/api_constants.dart';
import 'package:local_basket/data/model/authentication/deleteAccount_model.dart';

abstract class DeleteAccountRemoteDataSource {
  Future<DeleteAccountModel> deleteAccount();
}

class DeleteAccountRemoteDataSourceImpl
    implements DeleteAccountRemoteDataSource {
  final Dio client;

  DeleteAccountRemoteDataSourceImpl({required this.client});

  @override
  Future<DeleteAccountModel> deleteAccount() async {
    try {
      final response = await client.delete(
        '$baseUrl$deleteAccountUrl',
      );

      print('DeleteAccount Response: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return DeleteAccountModel.fromJson(response.data);
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
