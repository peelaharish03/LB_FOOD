//prod//
const baseUrl2 =
    'https://gateway-service.orangeplant-f70408fb.centralindia.azurecontainerapps.io/';

const TriggerOtp = '/auth/otp/send';
const SigninUrl = '/auth/otp/login';
const SignupUrl = '/auth/jtuserotp/trigger/sign-up?triggerOtp=true';
const userDetails = '/api/users/me';
const fcmTokenUrl = '/api/users/me/fcm-token';
const updateCurrentCustomerUrl = '/usermgmt/user/userDetails';
const deleteAccountUrl = '/usermgmt/user/skillrat';

const rolePostUrl = '/user/user';
String getNearbyRestaurantsUrl(
  double latitude,
  double longitude,
  double radius,
  int page,
  int size,
) {
  return '/api/stores/nearby?lat=$latitude&lng=$longitude&radius=$radius&page=$page&size=$size';
}

const addressSave = '/api/addresses/save';

const statesUrl = '/api/states';
String getCitiesUrl(int page, int size) {
  return '/api/cities?page=$page&size=$size';
}

const baseUrl =
    'https://gateway-service.orangeplant-f70408fb.centralindia.azurecontainerapps.io';

// notifications
String getNotificationsUrl(int pageNo, int pageSize) {
  return '/order/usernotification/user/list?pageNo=$pageNo&pageSize=$pageSize';
}

const clearAllNotificationsUrl = '/order/usernotification/clear-all';

// pools
const defaultB2bUnitId = 'b1731bad-7883-4ad8-9d09-abc1c34d7057';
String getPoolsUrl(String b2bUnitId) {
  return '/api/b2b/$b2bUnitId/pools';
}

String joinPoolUrl(String b2bUnitId, String poolId) {
  return '/api/b2b/$b2bUnitId/pools/$poolId/join';
}

String getMenuByRestaurantIdUrl(
  String storeId,
  String b2bUnitId,
  int page,
  int size,
) {
  return '/api/products/b2b-unit/$b2bUnitId?storeId=$storeId&mobileOrWeb=True&page=$page&size=$size';
}

String getRestaurantsByProductNameUrl(
  String productName,
  double latitude,
  double longitude,
  double radius,
  int page,
  int size,
) {
  return '/api/stores/nearby?lat=$latitude&lng=$longitude&radius=$radius&page=$page&size=$size&b2bUnitId=b1731bad-7883-4ad8-9d09-abc1c34d7057';
}

String orderHistoryUrl(int page, int size, String searchQuery) {
  final query = searchQuery.trim();
  final encodedQuery = Uri.encodeQueryComponent(query);
  final searchParam = query.isEmpty ? '' : '&query=$encodedQuery';
  return '/api/orders/me?page=$page&size=$size&sort=createdDate%2Cdesc';
}

// const createCartUrl = 'order/api/carts/create';
const createCartUrl = '/api/carts';
const getCartUrl = '/api/carts';
String clearCartByIdUrl(String cartId) {
  return '/api/carts/$cartId';
}

const productsAddToCartUrl = '/api/carts';
const saveAddressUrl = '/api/users/me/addresses';
const getAddressUrl = '/api/users/me/addresses?page=0&size=10';
const paymentUrl = '/api/orders/payments/process';
const paymentReFund = '/order/payments/refund';
const paymentRefundStatus = '/order/payments/refunds';
const createOrderUrl = '/order/api/orders/create';
const reOrderUrl = '/order/api/orders/reorder';
const deleteAddressUrl = '/usermgmt/api/addresses';
const defaultAddressUrl = '/usermgmt/api/addresses/setdefaultAddress';
const addressSavetoCartUrl = '/order/api/carts/address?addressId';

// FIX: paymentRefundHistory was an empty string — marked as TODO until the endpoint is known.
const paymentRefundHistory =
    ''; // TODO: Set the correct refund history endpoint

const promotionsUrl =
    '/api/promotions?page=0&size=10&sortBy=createdAt&sortDir=desc';
String validateOfferUrl(String offerId) {
  return '/order/offers/$offerId/validate';
}

const ratingReviewUrl = '/product/internal/reviews';
const createComplaintUrl = '/order/api/orders/complaints';
const checkoutUrl = '/api/orders/checkout';

String updateCartItemsUrl(String cartId, String itemId) {
  return '/api/carts/$cartId/items/$itemId';
}

String deleteCartItemsUrl(String cartId) {
  return '/order/api/carts/items/$cartId';
}

const _isProduction = bool.fromEnvironment(
  'IS_PRODUCTION',
  defaultValue: false,
);

const _razorPayTestKey = String.fromEnvironment(
  'RAZORPAY_TEST_KEY',
  defaultValue: 'rzp_test_TBfHQdPeMMX7ie',
);
const _razorPayTestSecret = String.fromEnvironment(
  'RAZORPAY_TEST_SECRET',
  defaultValue: 'yWklbZTXK5sZt5OPXMVEv7Un',
);

const _razorPayLiveKey = String.fromEnvironment(
  'RAZORPAY_KEY',
  defaultValue: '',
);
const _razorPayLiveSecret = String.fromEnvironment(
  'RAZORPAY_SECRET',
  defaultValue: '',
);

const razorPayKey = _isProduction ? _razorPayLiveKey : _razorPayTestKey;

/// Active Razorpay secret — test in dev, live in production.
const razorPaySecret =
    _isProduction ? _razorPayLiveSecret : _razorPayTestSecret;
