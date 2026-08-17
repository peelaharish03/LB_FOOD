import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/constants/global_exception_handler.dart';
import '../../model/authentication/trigger_otp_model.dart';

abstract class TriggerOtpRemoteDataSource {
  Future<TriggerOtpModel> fetchOtp(String mobileNumber);
}

class TriggerOtpRemoteDataSourceImpl implements TriggerOtpRemoteDataSource {
  final Dio client;

  TriggerOtpRemoteDataSourceImpl({required this.client});

  @override
  Future<TriggerOtpModel> fetchOtp(String mobileNumber) async {
    final payload = {"otpType": "SIGNIN", "primaryContact": mobileNumber};
    try {
      final response = await client.request(
        '$baseUrl2$TriggerOtp',
        options: Options(method: 'POST', extra: {'requiresAuth': false}),
        data: payload,
      );

      if (response.statusCode == 200) {
        return TriggerOtpModel.fromJson(response.data);
      } else {
        final code = response.data is Map ? response.data['code'] : null;
        final message = response.data is Map
            ? (response.data['message'] ?? 'Unable to send OTP right now.')
            : 'Unable to send OTP right now.';
        throw mapErrorCodeToException(code ?? response.statusCode ?? -1, message);
      }
    } on DioException catch (e) {
      throw handleDioError(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownBackendException("Unable to send OTP right now. Please try again after some time.");
    }
  }
}
