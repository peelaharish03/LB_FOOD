import 'package:dio/dio.dart';
import 'package:local_basket/core/constants/api_constants.dart';
import 'package:local_basket/core/constants/global_exception_handler.dart';
import 'package:local_basket/data/model/cart/eligiblePromotions/eligiblePromotions_model.dart';

abstract class EligiblePromotionsRemoteDataSource {
  Future<EligiblePromotionsModel> getEligiblePromotions(
    Map<String, dynamic> payload,
  );
}

class EligiblePromotionsRemoteDataSourceImpl
    implements EligiblePromotionsRemoteDataSource {
  final Dio client;

  EligiblePromotionsRemoteDataSourceImpl({required this.client});

  @override
  Future<EligiblePromotionsModel> getEligiblePromotions(
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await client.post(
        '$baseUrl$eligiblePromotionsUrl',
        data: payload,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is List) {
          return EligiblePromotionsModel.fromJson({'data': data});
        }
        return EligiblePromotionsModel.fromJson(data);
      } else {
        throw UnknownBackendException(
          "Unable to fetch promo codes right now. Please try again after some time.",
        );
      }
    } on DioException catch (e) {
      throw handleDioError(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownBackendException(
        "Unable to fetch promo codes right now. Please try again after some time.",
      );
    }
  }
}
