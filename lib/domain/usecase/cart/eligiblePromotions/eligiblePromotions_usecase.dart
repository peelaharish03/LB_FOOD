import 'package:local_basket/data/model/cart/eligiblePromotions/eligiblePromotions_model.dart';
import 'package:local_basket/domain/repository/cart/eligiblePromotions/eligiblePromotions_repository.dart';

class EligiblePromotionsUseCase {
  final EligiblePromotionsRepository repository;

  EligiblePromotionsUseCase({required this.repository});

  Future<EligiblePromotionsModel> call(Map<String, dynamic> payload) async {
    return await repository.getEligiblePromotions(payload);
  }
}
