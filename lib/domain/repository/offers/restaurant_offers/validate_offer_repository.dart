import 'package:local_basket/data/model/offers/restaurant_offers/validate_offer_model.dart';

abstract class ValidateOfferRepository {
  Future<ValidateOfferModel> validateOffer();
}
