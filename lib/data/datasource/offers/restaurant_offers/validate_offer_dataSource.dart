import 'package:dio/dio.dart';
import 'package:local_basket/core/constants/global_exception_handler.dart';
import 'package:local_basket/core/constants/api_constants.dart';
import 'package:local_basket/data/model/offers/restaurant_offers/validate_offer_model.dart';

abstract class ValidateOfferRemoteDataSource {
  Future<ValidateOfferModel> validateOffer(String offerId);
}

class ValidateOfferRemoteDataSourceImpl
    implements ValidateOfferRemoteDataSource {
  final Dio client;

  ValidateOfferRemoteDataSourceImpl({required this.client});

  @override
  Future<ValidateOfferModel> validateOffer(String offerId) async {
    try {
      final response = await client.post(
        '$baseUrl${validateOfferUrl(offerId)}',
      );

      print('ValidateOffer Response: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ValidateOfferModel.fromJson(response.data);
      } else {
        throw UnknownBackendException("Unable to complete this request. Please try again after some time.");
      }
    } on DioException catch (e) {
      throw handleDioError(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownBackendException("Unable to complete this request. Please try again after some time.");
    }
  }
}
