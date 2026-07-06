import 'package:dio/dio.dart';
import 'package:local_basket/data/model/authentication/signup_model.dart';
import '../../../core/constants/api_constants.dart';

abstract class SignUpRemoteDataSource {
  Future<SignUpModel> fetchOtp(String mobileNumber);
}

class SignUpRemoteDataSourceImpl implements SignUpRemoteDataSource {
  final Dio client;

  SignUpRemoteDataSourceImpl({required this.client});

  @override
  Future<SignUpModel> fetchOtp(String mobileNumber) async {
    final payload = {"otpType": "SIGNIN", "primaryContact": mobileNumber};
    print('payload: $payload');
    try {
      final response = await client.request(
        '$baseUrl2$SignupUrl',
        options: Options(method: 'POST', extra: {'requiresAuth': false}),
        data: payload,
      );

      if (response.statusCode == 200) {
        return SignUpModel.fromJson(response.data);
      } else {
        throw Exception('Failed to load OTP data: ${response.statusCode}');
      }
    } catch (e) {
      print('error is otp data source::$e');
      throw Exception('Failed to load OTP data: ${e.toString()}');
    }
  }
}
