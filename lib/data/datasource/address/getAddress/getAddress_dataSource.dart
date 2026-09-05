import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:local_basket/core/constants/global_exception_handler.dart';
import 'package:local_basket/core/constants/api_constants.dart';
import 'package:local_basket/data/model/address/getAddress/getAddress_model.dart';

abstract class GetAddressRemoteDataSource {
  Future<GetAddressModel> getAddress();
}

class GetAddressRemoteDataSourceImpl
    implements GetAddressRemoteDataSource {
  final Dio client;

  GetAddressRemoteDataSourceImpl({required this.client});

  static const String _tag = '[GetAddress][DataSource]';

  @override
  Future<GetAddressModel> getAddress() async {
    final url = '$baseUrl2$getAddressUrl';
    final stopwatch = Stopwatch()..start();
    debugPrint('$_tag ➡️ REQUEST  GET $url');

    try {
      final response = await client.request(
        url,
        options: Options(method: 'GET'),
      );
      stopwatch.stop();

      debugPrint(
        '$_tag ⬅️ RESPONSE ${response.statusCode} '
        '${response.statusMessage ?? ''} (${stopwatch.elapsedMilliseconds}ms)',
      );
      debugPrint('$_tag    request headers : ${response.requestOptions.headers}');
      debugPrint('$_tag    response headers: ${response.headers.map}');
      debugPrint('$_tag    raw body        : ${response.data}');

      if (response.statusCode == 200) {
        final model = GetAddressModel.fromJson(response.data);
        debugPrint(
          '$_tag ✅ PARSED  success=${model.success} message=${model.message} '
          'totalElements=${model.totalElements} '
          'content.length=${model.content.length}',
        );
        for (var i = 0; i < model.content.length; i++) {
          final a = model.content[i].address;
          debugPrint(
            '$_tag    [$i] id=${a?.id} type=${a?.addressType} name=${a?.name} '
            'mobile=${a?.mobileNumber} line1=${a?.line1} line2=${a?.line2} '
            'city=${a?.city} state=${a?.state} country=${a?.country} '
            'postalCode=${a?.postalCode} fullText=${a?.fullText}',
          );
        }
        return model;
      } else {
        debugPrint(
          '$_tag ❌ NON-200 status=${response.statusCode} body=${response.data}',
        );
        throw UnknownBackendException("Unable to complete this request. Please try again after some time.");
      }
    } on DioException catch (e, st) {
      stopwatch.stop();
      debugPrint(
        '$_tag ❌ DioException (${stopwatch.elapsedMilliseconds}ms) '
        'type=${e.type} message=${e.message}',
      );
      debugPrint('$_tag    status : ${e.response?.statusCode}');
      debugPrint('$_tag    body   : ${e.response?.data}');
      debugPrint('$_tag    stack  : $st');
      throw handleDioError(e);
    } catch (e, st) {
      stopwatch.stop();
      debugPrint(
        '$_tag ❌ Unexpected error (${stopwatch.elapsedMilliseconds}ms): $e',
      );
      debugPrint('$_tag    stack: $st');
      if (e is AppException) rethrow;
      throw UnknownBackendException("Unable to complete this request. Please try again after some time.");
    }
  }
}
