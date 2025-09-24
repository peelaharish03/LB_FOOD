import 'package:dio/dio.dart';
import 'package:local_basket/core/constants/api_constants.dart';
import 'package:local_basket/data/model/offers/restaurant_offers/validate_offer_model.dart';

abstract class ValidateOfferRemoteDataSource {
  Future<ValidateOfferModel> validateOffer();
}

class ValidateOfferRemoteDataSourceImpl implements ValidateOfferRemoteDataSource {
  final Dio client;

  ValidateOfferRemoteDataSourceImpl({required this.client});

  @override
  Future<ValidateOfferModel> validateOffer() async {
    try {
      final response = await client.post(
        '$baseUrl$validateOfferUrl',
      );

      print('ValidateOffer Response: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ValidateOfferModel.fromJson(response.data);
      } else {
        throw Exception(
            'Failed to create cart. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('ValidateOffer Error: $e');
      throw Exception('ValidateOffer failed: ${e.toString()}');
    }
  }
}
