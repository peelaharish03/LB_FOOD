import 'package:dio/dio.dart';
import 'package:local_basket/core/constants/api_constants.dart';
import 'package:local_basket/data/model/address/state/state_model.dart';

abstract class GetStatesRemoteDataSource {
  Future<List<StateModel>> getStates();
}

class GetStatesRemoteDataSourceImpl implements GetStatesRemoteDataSource {
  final Dio client;

  GetStatesRemoteDataSourceImpl({required this.client});

  @override
  Future<List<StateModel>> getStates() async {
    try {
      final response = await client.request(
        '$baseUrl$statesUrl',
        options: Options(method: 'GET'),
      );
      print('$baseUrl$statesUrl');
      print('GetStates Response: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          return data
              .map((e) => StateModel.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        }
        throw Exception('Unexpected states response format');
      } else {
        throw Exception(
            'Failed to load states. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('GetStates Error: $e');
      throw Exception('GetStates failed: ${e.toString()}');
    }
  }
}
