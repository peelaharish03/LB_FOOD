import 'package:local_basket/data/datasource/offers/restaurant_offers/validate_offer_dataSource.dart';
import 'package:local_basket/data/model/offers/restaurant_offers/validate_offer_model.dart';
import 'package:local_basket/domain/repository/offers/restaurant_offers/validate_offer_repository.dart';

class ValidateOfferRepositoryImpl implements ValidateOfferRepository {
  final ValidateOfferRemoteDataSource remoteDataSource;

  ValidateOfferRepositoryImpl({required this.remoteDataSource});

  @override
  Future<ValidateOfferModel> validateOffer() async {
    return await remoteDataSource.validateOffer();
  }
}
