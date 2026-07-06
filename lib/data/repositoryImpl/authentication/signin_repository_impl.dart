import 'package:local_basket/data/datasource/authentication/signin_remote_data_source.dart';

import '../../../domain/repository/authentication/signin_repository.dart';
import '../../model/authentication/signin_model.dart';

class SignInRepositoryImpl implements SignInRepository {
  final SignInRemoteDataSource remoteDataSource;

  SignInRepositoryImpl({required this.remoteDataSource});

  @override
  Future<SignInModel> logIn(String mobileNumber, String otp,String fullName, String deviceId) async {
    final model = await remoteDataSource.signIn(mobileNumber, otp,fullName, deviceId);
    return SignInModel(
      accessToken: model.accessToken,
      refreshToken: model.refreshToken,
      expiresIn: model.expiresIn,
      tokenType: model.tokenType,
    );
  }
}
