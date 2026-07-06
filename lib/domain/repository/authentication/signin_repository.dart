import '../../../data/model/authentication/signin_model.dart';

abstract class SignInRepository {
  Future<SignInModel> logIn(String mobileNumber, String otp,String fullName,String deviceId);
}

