import 'package:local_basket/data/datasource/complaints/create_complaints_datasource.dart';
import 'package:local_basket/data/model/complaints/create_complaints_model.dart';
import 'package:local_basket/domain/repository/complaints/create_complaints_repository.dart';

class CreateComplaintRepositoryImpl implements CreateComplaintRepository {
  final CreateComplaintRemoteDataSource remoteDataSource;

  CreateComplaintRepositoryImpl({required this.remoteDataSource});

  @override
  Future<CreateComplaintModel> createComplaint(
      Map<String, dynamic> payload) async {
    return await remoteDataSource.createComplaint(payload);
  }
}
