import 'package:dio/dio.dart';
import 'package:local_basket/core/constants/api_constants.dart';
import 'package:local_basket/data/model/rating&reviews/rating&review_model.dart';

abstract class RatingReviewRemoteDataSource {
  Future<RatingReviewModel> ratingReview(Map<String, dynamic> payload);
}

class RatingReviewRemoteDataSourceImpl implements RatingReviewRemoteDataSource {
  final Dio client;

  RatingReviewRemoteDataSourceImpl({required this.client});

  @override
  Future<RatingReviewModel> ratingReview(Map<String, dynamic> payload) async {
    try {
      final response = await client.post(
        '$baseUrl$ratingReviewUrl',
        data: payload,
      );

      print('RatingReview Response: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return RatingReviewModel.fromJson(response.data);
      } else {
        throw Exception(
            'Failed to save address. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('RatingReview Error: $e');
      throw Exception('RatingReview failed: ${e.toString()}');
    }
  }
}
