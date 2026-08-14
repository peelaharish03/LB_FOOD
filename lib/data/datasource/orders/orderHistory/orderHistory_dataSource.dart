import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:local_basket/core/constants/api_constants.dart';
import 'package:local_basket/data/model/orders/orderHistory/orderHistory_model.dart';

abstract class OrderHistoryRemoteDataSource {
  Future<OrderHistoryModel> orderHistory(
    int page,
    int size,
    String searchQuery,
  );
}

class OrderHistoryRemoteDataSourceImpl implements OrderHistoryRemoteDataSource {
  final Dio client;

  OrderHistoryRemoteDataSourceImpl({required this.client});

  @override
  Future<OrderHistoryModel> orderHistory(
    int page,
    int size,
    String searchQuery,
  ) async {
    final url = '$baseUrl${orderHistoryUrl(page, size, searchQuery)}';
    try {
      log('[OrderHistoryRemoteDataSource] GET $url');
      final response = await client.request(
        url,
        options: Options(method: 'GET'),
      );
      if (response.statusCode == 200) {
        log(
          '[OrderHistoryRemoteDataSource] response status=${response.statusCode}',
        );
        return OrderHistoryModel.fromJson(response.data);
      } else {
        throw Exception(
          'Failed to load OrderHistory data: ${response.statusCode}',
        );
      }
    } catch (e) {
      log('[OrderHistoryRemoteDataSource] error=$e');
      throw Exception('Failed to load OrderHistory data: ${e.toString()}');
    }
  }
}
