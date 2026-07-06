import '../../../data/model/authentication/signin_model.dart';
import '../../repository/authentication/signin_repository.dart';

class SignInValidationUseCase {
  final SignInRepository repository;

  SignInValidationUseCase({required this.repository});

  Future<SignInModel> call(String mobileNumber, String otp,String fullName,String deviceId) async {
    return await repository.logIn(mobileNumber, otp,fullName,deviceId);
  }
}

