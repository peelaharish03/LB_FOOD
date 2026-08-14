import 'package:local_basket/data/model/offers/promotions/promotions_model.dart';

abstract class PromotionsRepository {
  Future<PromotionsModel> getPromotions();
}
