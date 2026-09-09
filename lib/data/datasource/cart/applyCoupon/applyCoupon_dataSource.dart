import 'package:dio/dio.dart';
import 'package:local_basket/core/constants/api_constants.dart';
import 'package:local_basket/core/constants/global_exception_handler.dart';

/// Cart-level coupon endpoints. A promo code chosen in the cart screen is
/// applied here (POST) and cleared here (DELETE) — it is no longer piggy-backed
/// on the add-item / update-item cart calls. The updated cart is fetched
/// separately by the caller via getCart, so these only need to signal success.
abstract class ApplyCouponRemoteDataSource {
  Future<void> applyCoupon(String cartId, String code);
  Future<void> removeCoupon(String cartId, String code);
}

class ApplyCouponRemoteDataSourceImpl implements ApplyCouponRemoteDataSource {
  final Dio client;

  ApplyCouponRemoteDataSourceImpl({required this.client});

  @override
  Future<void> applyCoupon(String cartId, String code) {
    return _send('POST', applyCartCouponUrl(cartId, code));
  }

  @override
  Future<void> removeCoupon(String cartId, String code) {
    return _send('DELETE', removeCartCouponUrl(cartId, code));
  }

  Future<void> _send(String method, String path) async {
    try {
      final response = await client.request(
        '$baseUrl$path',
        options: Options(
          method: method,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      print('Coupon $method Response: ${response.data}');

      final status = response.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        throw UnknownBackendException(
          "Unable to update the promo code right now. Please try again after some time.",
        );
      }
    } on DioException catch (e) {
      throw handleDioError(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownBackendException(
        "Unable to update the promo code right now. Please try again after some time.",
      );
    }
  }
}
