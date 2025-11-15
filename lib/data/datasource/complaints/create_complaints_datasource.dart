import 'package:dio/dio.dart';
import 'package:local_basket/core/constants/api_constants.dart';
import 'package:local_basket/data/model/complaints/create_complaints_model.dart';

abstract class CreateComplaintRemoteDataSource {
  Future<CreateComplaintModel> createComplaint(Map<String, dynamic> payload);
}

class CreateComplaintRemoteDataSourceImpl
    implements CreateComplaintRemoteDataSource {
  final Dio client;

  CreateComplaintRemoteDataSourceImpl({required this.client});

  @override
  Future<CreateComplaintModel> createComplaint(
      Map<String, dynamic> payload) async {
    try {
      final response = await client.post(
        '$baseUrl$createComplaintUrl',
        data: payload,
      );

      print('CreateComplaint Response: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return CreateComplaintModel.fromJson(response.data);
      } else {
        throw Exception(
            'Failed to save address. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('CreateComplaint Error: $e');
      throw Exception('CreateComplaint failed: ${e.toString()}');
    }
  }
}
