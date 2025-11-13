import 'package:local_basket/data/model/rating&reviews/rating&review_model.dart';

abstract class RatingReviewState {}

class RatingReviewInitial extends RatingReviewState {}

class RatingReviewLoading extends RatingReviewState {}

class RatingReviewSuccess extends RatingReviewState {
  final RatingReviewModel ratingReviewModel;

  RatingReviewSuccess(this.ratingReviewModel);
}

class RatingReviewFailure extends RatingReviewState {
  final String errorMessage;

  RatingReviewFailure(this.errorMessage);
}
