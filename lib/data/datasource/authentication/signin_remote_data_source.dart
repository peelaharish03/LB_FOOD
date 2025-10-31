import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../model/authentication/signin_model.dart';

abstract class SignInRemoteDataSource {
  Future<SignInModel> signIn(String mobileNumber, String otp,String fullName);
}

class SignInRemoteDataSourceImpl implements SignInRemoteDataSource {
  final Dio client;

  SignInRemoteDataSourceImpl({required this.client});

  @override
  Future<SignInModel> signIn(String mobileNumber, String otp,String fullName) async {
    final payload = {
      "otp": otp,
      "primaryContact": mobileNumber,
      "fullName": fullName,
    };

    try {
      print('Sending payload: $payload');

      final response = await client.request(
        '$baseUrl2$SigninUrl',
        options: Options(method: 'POST'),
        data: payload,
      );
      print('url $baseUrl2$SigninUrl');

      print('Response status code: ${response.statusCode}');
      if (response.statusCode == 200) {
        print('Response data: ${response.data}');
        return SignInModel.fromJson(response.data);
      } else {
        throw Exception('Failed to load OTP data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load OTP data: ${e.toString()}');
    }
  }
}
