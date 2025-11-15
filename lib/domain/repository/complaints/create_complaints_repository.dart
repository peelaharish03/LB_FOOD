import 'package:local_basket/data/model/complaints/create_complaints_model.dart';

abstract class CreateComplaintRepository {
  Future<CreateComplaintModel> createComplaint(Map<String, dynamic> payload);
}
