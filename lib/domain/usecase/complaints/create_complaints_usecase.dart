import 'package:local_basket/data/model/complaints/create_complaints_model.dart';
import 'package:local_basket/domain/repository/complaints/create_complaints_repository.dart';

class CreateComplaintUseCase {
  final CreateComplaintRepository repository;

  CreateComplaintUseCase({required this.repository});

  Future<CreateComplaintModel> call(Map<String, dynamic> payload) async {
    return await repository.createComplaint(payload);
  }
}
