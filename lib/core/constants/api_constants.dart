//prod//
const baseUrl2 =
    'https://gateway-service.purplefield-2b43f6a6.southindia.azurecontainerapps.io';

const TriggerOtp = '/auth/otp/send';
const SigninUrl = '/auth/otp/login';
const SignupUrl = 'auth/jtuserotp/trigger/sign-up?triggerOtp=true';
const userDetails = '/api/users/me';
const updateCurrentCustomerUrl = 'usermgmt/user/userDetails';
const deleteAccountUrl = 'usermgmt/user/skillrat';

const rolePostUrl = 'user/user';
String getNearbyRestaurantsUrl(
  double latitude,
  double longitude,
  double radius,
  int page,
  int size,
) {
  return '/api/stores/nearby?lat=$latitude&lng=$longitude&radius=$radius&page=$page&size=$size';
}

const addressSave = 'api/addresses/save';

const baseUrl =
    'https://gateway-service.purplefield-2b43f6a6.southindia.azurecontainerapps.io';

// notifications
String getNotificationsUrl(int pageNo, int pageSize) {
  return 'order/usernotification/user/list?pageNo=$pageNo&pageSize=$pageSize';
}

const clearAllNotificationsUrl = 'order/usernotification/clear-all';

String getMenuByRestaurantIdUrl(
  String restaurantId,
  String search,
  int page,
  int size,
) {
  return '/api/products/store/$restaurantId?page=$page&size=$size';
  //'/api/products/b2b-unit/f19981ef-4735-4983-82fe-752af776c00e?storeId=39dcaa06-add8-42d4-918d-45cdb78a9f24&searchTerm=&$page=0&size=$size';
}
// old api -'product/api/products/filter?businessId=$restaurantId&attributeValue=Online&attributeValue=DineIN%26Online%26TakeAway&keyword=$search&page=$page&size=$size';

String getRestaurantsByProductNameUrl(
  String productName,
  double latitude,
  double longitude,
  double radius,
  int page,
  int size,
) {
  return '/api/stores/nearby?lat=$latitude&lng=$longitude&radius=$radius&page=$page&size=$size';
}

String orderHistoryUrl(int page, int size, String searchQuery) {
  return 'order/api/orders/history?page=$page&size=$size&sortBy=createdDate&direction=DESC&query=$searchQuery';
}

// const createCartUrl = 'order/api/carts/create';
const createCartUrl = '/api/carts';
const getCartUrl = '/api/carts';
const clearCartUrl = 'order/api/carts/clear';
const productsAddToCartUrl = '/api/carts';
const saveAddressUrl = '/api/users/me/addresses';
const getAddressUrl = '/api/users/me/addresses?page=0&size=10';
const paymentUrl = 'order/payments/process';
const paymentReFund = 'order/payments/refund';
const paymentRefundStatus = 'order/payments/refunds';
const createOrderUrl = 'order/api/orders/create';
const reOrderUrl = 'order/api/orders/reorder';
const deleteAddressUrl = 'usermgmt/api/addresses';
const defaultAddressUrl = 'usermgmt/api/addresses/setdefaultAddress';
const addressSavetoCartUrl = 'order/api/carts/address?addressId';

// FIX: paymentRefundHistory was an empty string — marked as TODO until the endpoint is known.
const paymentRefundHistory =
    ''; // TODO: Set the correct refund history endpoint

const restaurantOffersUrl =
    'product/api/offers/list?active=true&page=0&size=100';
String validateOfferUrl(String offerId) {
  return 'order/offers/$offerId/validate';
}

const ratingReviewUrl = 'product/internal/reviews';
const createComplaintUrl = 'order/api/orders/complaints';
const checkoutUrl = '/api/orders/checkout';

String updateCartItemsUrl(String cartId, String itemId) {
  return '/api/carts/$cartId/items/$itemId';
}

String deleteCartItemsUrl(String cartId) {
  return 'order/api/carts/items/$cartId';
}

// ---------------------------------------------------------------------------
// FIX: Razorpay keys moved here from CartScreen to centralise them.
//
// HOW TO USE SECURELY IN PRODUCTION:
//   Pass keys at build time using --dart-define so they are never committed
//   to source control:
//
//   flutter run \
//     --dart-define=RAZORPAY_KEY=rzp_live_xxx \
//     --dart-define=RAZORPAY_SECRET=xxx \
//     --dart-define=IS_PRODUCTION=true
//
//   The defaultValue below keeps dev builds working without any --dart-define.
// ---------------------------------------------------------------------------

const _isProduction = bool.fromEnvironment(
  'IS_PRODUCTION',
  defaultValue: false,
);

const _razorPayTestKey = String.fromEnvironment(
  'RAZORPAY_TEST_KEY',
  defaultValue: 'rzp_test_RsEtePJVg5vbk9',
);
const _razorPayTestSecret = String.fromEnvironment(
  'RAZORPAY_TEST_SECRET',
  defaultValue: 'U7RLFFnNceIHKyMtuYJSlkQ5',
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
