import 'package:dio/dio.dart';
import 'package:local_basket/core/constants/api_constants.dart';
import 'package:local_basket/data/model/address/state/state_model.dart';

abstract class GetCitiesRemoteDataSource {
  /// Fetches all serviceable cities. Pass [stateCode] to filter to a single
  /// state, or omit it to fetch the full list across every state.
  Future<List<CityModel>> getCities([String? stateCode]);
}

class GetCitiesRemoteDataSourceImpl implements GetCitiesRemoteDataSource {
  final Dio client;
  static const int _pageSize = 100;

  GetCitiesRemoteDataSourceImpl({required this.client});

  @override
  Future<List<CityModel>> getCities([String? stateCode]) async {
    try {
      final allCities = <CityModel>[];
      var page = 0;
      var isLast = false;

      while (!isLast) {
        final url = '$baseUrl${getCitiesUrl(page, _pageSize)}';
        final response = await client.request(
          url,
          options: Options(method: 'GET'),
        );
        print(url);
        print('GetCities Response: ${response.data}');

        if (response.statusCode != 200) {
          throw Exception(
              'Failed to load cities. Status code: ${response.statusCode}');
        }

        final data = response.data;
        if (data is! Map || data['content'] is! List) {
          throw Exception('Unexpected cities response format');
        }

        final content = data['content'] as List;
        allCities.addAll(
          content.map((e) => CityModel.fromJson(Map<String, dynamic>.from(e))),
        );

        isLast = data['last'] == true || content.isEmpty;
        page++;
      }

      if (stateCode == null || stateCode.isEmpty) {
        return allCities;
      }

      return allCities
          .where(
            (city) =>
                city.stateCode != null &&
                city.stateCode!.toLowerCase() == stateCode.toLowerCase(),
          )
          .toList();
    } catch (e) {
      print('GetCities Error: $e');
      throw Exception('GetCities failed: ${e.toString()}');
    }
  }
}
