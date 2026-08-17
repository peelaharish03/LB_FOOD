import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/global_exception_handler.dart';
import '../../model/authentication/signin_model.dart';

abstract class SignInRemoteDataSource {
  Future<SignInModel> signIn(String mobileNumber, String otp, String fullName, String deviceId);
}

class SignInRemoteDataSourceImpl implements SignInRemoteDataSource {
  final Dio client;

  SignInRemoteDataSourceImpl({required this.client});

  @override
  Future<SignInModel> signIn(
    String mobileNumber,
    String otp,
    String fullName,
    String deviceId,
  ) async {
    final payload = {
      "otp": otp,
      "primaryContact": mobileNumber,
      "fullName": fullName,
      "deviceId": deviceId,
    };

    try {
      final response = await client.request(
        '$baseUrl2$SigninUrl',
        options: Options(method: 'POST', extra: {'requiresAuth': false}),
        data: payload,
      );

      if (response.statusCode == 200) {
        return SignInModel.fromJson(response.data);
      } else {
        final code = response.data is Map ? response.data['code'] : null;
        final message = response.data is Map
            ? (response.data['message'] ?? 'Unable to verify OTP right now.')
            : 'Unable to verify OTP right now.';
        throw mapErrorCodeToException(code ?? response.statusCode ?? -1, message);
      }
    } on DioException catch (e) {
      throw handleDioError(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownBackendException("Unable to verify OTP right now. Please try again after some time.");
    }
  }
}
