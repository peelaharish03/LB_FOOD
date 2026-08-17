import 'package:local_basket/data/model/cart/eligiblePromotions/eligiblePromotions_model.dart';

abstract class EligiblePromotionsRepository {
  Future<EligiblePromotionsModel> getEligiblePromotions(
    Map<String, dynamic> payload,
  );
}
