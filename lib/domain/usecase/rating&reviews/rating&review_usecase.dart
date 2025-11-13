import 'package:local_basket/data/model/rating&reviews/rating&review_model.dart';
import 'package:local_basket/domain/repository/rating&reviews/rating&review_repository.dart';

class RatingReviewUseCase {
  final RatingReviewRepository repository;

  RatingReviewUseCase({required this.repository});

  Future<RatingReviewModel> call(Map<String, dynamic> payload) async {
    return await repository.submitRatingReview(payload);
  }
}
