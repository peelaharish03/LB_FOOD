import 'package:local_basket/data/datasource/cart/eligiblePromotions/eligiblePromotions_dataSource.dart';
import 'package:local_basket/data/model/cart/eligiblePromotions/eligiblePromotions_model.dart';
import 'package:local_basket/domain/repository/cart/eligiblePromotions/eligiblePromotions_repository.dart';

class EligiblePromotionsRepositoryImpl implements EligiblePromotionsRepository {
  final EligiblePromotionsRemoteDataSource remoteDataSource;

  EligiblePromotionsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<EligiblePromotionsModel> getEligiblePromotions(
    Map<String, dynamic> payload,
  ) async {
    return await remoteDataSource.getEligiblePromotions(payload);
  }
}
