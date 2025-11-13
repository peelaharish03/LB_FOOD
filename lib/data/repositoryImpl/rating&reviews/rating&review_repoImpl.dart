import 'package:local_basket/data/datasource/rating&reviews/rating&review_datasource.dart';
import 'package:local_basket/data/model/rating&reviews/rating&review_model.dart';
import 'package:local_basket/domain/repository/rating&reviews/rating&review_repository.dart';

class RatingReviewRepositoryImpl implements RatingReviewRepository {
  final RatingReviewRemoteDataSource remoteDataSource;

  RatingReviewRepositoryImpl({required this.remoteDataSource});

  @override
  Future<RatingReviewModel> submitRatingReview(
      Map<String, dynamic> payload) async {
    return await remoteDataSource.ratingReview(payload);
  }
}
