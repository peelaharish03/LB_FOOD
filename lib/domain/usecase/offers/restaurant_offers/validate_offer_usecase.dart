import 'package:local_basket/data/model/offers/restaurant_offers/validate_offer_model.dart';
import 'package:local_basket/domain/repository/offers/restaurant_offers/validate_offer_repository.dart';

class ValidateOfferUseCase {
  final ValidateOfferRepository repository;

  ValidateOfferUseCase({required this.repository});

  Future<ValidateOfferModel> call() async {
    return await repository.validateOffer();
  }
}
