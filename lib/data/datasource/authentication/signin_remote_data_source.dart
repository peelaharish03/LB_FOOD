import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../model/authentication/signin_model.dart';

abstract class SignInRemoteDataSource {
  Future<SignInModel> signIn(String mobileNumber, String otp, String fullName);
}

class SignInRemoteDataSourceImpl implements SignInRemoteDataSource {
  final Dio client;

  SignInRemoteDataSourceImpl({required this.client});

  @override
  Future<SignInModel> signIn(
      String mobileNumber, String otp, String fullName) async {
    final payload = {
      "otp": otp,
      "primaryContact": mobileNumber,
      "fullName": fullName,
    };

    try {
      print('📤 Sending payload: $payload');
      print('🧹 Removing Authorization header for login...');

      // ✅ Ensure no Authorization header is sent
      client.options.headers.remove('Authorization');

      final response = await client.post(
        '$baseUrl2$SigninUrl',
        data: payload,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );


      if (response.statusCode == 200) {
        // print('✅ Login success response: ${response.data}');
        return SignInModel.fromJson(response.data);
      } else {
        throw Exception('Failed to load OTP data: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Login request failed: $e');
      throw Exception('Failed to load OTP data: ${e.toString()}');
    }
  }
}
