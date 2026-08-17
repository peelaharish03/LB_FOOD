import 'package:dio/dio.dart';
import 'package:local_basket/core/constants/global_exception_handler.dart';
import 'package:local_basket/core/constants/api_constants.dart';
import 'package:local_basket/data/model/authentication/update_current_customer_model.dart';

abstract class UpdateCurrentCustomerRemoteDatasource {
  Future<UpdateCurrentCustomerModel> updateCurrentCustomer({
    Map<String, dynamic> payload,
  });
}

class UpdateCurrentCustomerRemoteDataSourceImpl
    implements UpdateCurrentCustomerRemoteDatasource {
  final Dio client;

  UpdateCurrentCustomerRemoteDataSourceImpl({required this.client});

  @override
  Future<UpdateCurrentCustomerModel> updateCurrentCustomer({
    dynamic payload,
  }) async {
    try {
      print(payload['fcmToken']);

      FormData formData = FormData.fromMap({
        "fullName": payload['fullName'],
        "email": payload['email'],
        "fcmToken": payload['fcmToken'],
        "eato": payload['eato'],
      });
      print(formData);
      final response = await client.put(
        '$baseUrl$updateCurrentCustomerUrl',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      print('Response: ${response.data}');

      if (response.statusCode == 200) {
        return UpdateCurrentCustomerModel.fromJson(response.data);
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
