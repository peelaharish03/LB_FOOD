import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_basket/core/constants/global_exception_handler.dart';
import 'package:local_basket/domain/usecase/rating&reviews/rating&review_usecase.dart';
import 'package:local_basket/presentation/cubit/rating&reviews/rating&review_state.dart';

class RatingReviewCubit extends Cubit<RatingReviewState> {
  final RatingReviewUseCase ratingReviewUseCase;

  RatingReviewCubit({required this.ratingReviewUseCase})
      : super(RatingReviewInitial());

  Future<void> submitRatingReview(Map<String, dynamic> payload) async {
    emit(RatingReviewLoading());
    try {
      final response = await ratingReviewUseCase(payload);
      emit(RatingReviewSuccess(response));
    } catch (e) {
      emit(RatingReviewFailure(friendlyErrorMessage(e)));
    }
  }
}
