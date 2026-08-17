import 'package:local_basket/core/constants/global_exception_handler.dart';
import 'package:local_basket/data/datasource/authentication/rolesPost_dataSource.dart';
import 'package:local_basket/data/model/authentication/rolesPost_model.dart';
import 'package:local_basket/domain/repository/authentication/rolesPost_repository.dart';

class RolePostRepoImpl implements RolePostRepository {
  final RolePostRemoteDatasource remoteDataSource;

  RolePostRepoImpl({required this.remoteDataSource});

  @override
  Future<RolePostModel> rolePost(String? role) async {
    try {
      final model = await remoteDataSource.RolePost(
        role: role,
      );
      return RolePostModel(
        message: model.message,
        role: model.role,
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownBackendException("Unable to complete this request. Please try again after some time.");
    }
  }
}
