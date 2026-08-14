import 'package:local_basket/data/model/offers/promotions/promotions_model.dart';
import 'package:local_basket/domain/repository/offers/promotions/promotions_repository.dart';

class PromotionsUseCase {
  final PromotionsRepository repository;

  PromotionsUseCase({required this.repository});

  Future<PromotionsModel> call() async {
    return await repository.getPromotions();
  }
}
