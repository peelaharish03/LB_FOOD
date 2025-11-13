import 'package:local_basket/data/model/rating&reviews/rating&review_model.dart';

abstract class RatingReviewRepository {
  Future<RatingReviewModel> submitRatingReview(Map<String, dynamic> payload);
}
