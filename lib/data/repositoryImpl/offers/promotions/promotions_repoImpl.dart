import 'package:local_basket/data/datasource/offers/promotions/promotions_dataSource.dart';
import 'package:local_basket/data/model/offers/promotions/promotions_model.dart';
import 'package:local_basket/domain/repository/offers/promotions/promotions_repository.dart';

class PromotionsRepositoryImpl implements PromotionsRepository {
  final PromotionsRemoteDataSource remoteDataSource;

  PromotionsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<PromotionsModel> getPromotions() async {
    return await remoteDataSource.getPromotions();
  }
}
