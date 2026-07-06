import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
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
    print('payload: $payload');
    try {
      final response = await client.request(
        '$baseUrl2$TriggerOtp',
        options: Options(method: 'POST', extra: {'requiresAuth': false}),
        data: payload,
      );

      if (response.statusCode == 200) {
        return TriggerOtpModel.fromJson(response.data);
      } else {
        throw Exception('Failed to load OTP data: ${response.statusCode}');
      }
    } catch (e) {
      print('error is otp data source::$e');
      throw Exception('Failed to load OTP data: ${e.toString()}');
    }
  }
}
