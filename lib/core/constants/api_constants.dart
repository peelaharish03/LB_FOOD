//usermanagement
//dev//
// const baseUrl2 = 'https://skillrat.com/usermgmt/';
//local
// const baseUrl2 = 'http://localhost:9443/api/usermgmt/';
//prod//
const baseUrl2 =
    'https://api-service.happybush-7c5a2823.centralindia.azurecontainerapps.io/api/usermgmt/';

const TriggerOtp = 'auth/jtuserotp/trigger/otp?triggerOtp=true';
const SigninUrl = 'auth/login';
const SignupUrl = 'auth/jtuserotp/trigger/sign-up?triggerOtp=true';
const userDetails = 'user/userDetails';
const updateCurrentCustomerUrl = 'usermgmt/user/userDetails';
const deleteAccountUrl = 'usermgmt/user/skillrat';

const rolePostUrl = 'user/user';
String getNearbyRestaurantsUrl(
    double latitude, double longitude, String postalCode, int page, int size) {
  return 'business/find?latitude=$latitude&longitude=$longitude&radius=100&postalCode=$postalCode&page=$page&size=$size&categoryName=Restaurant';
}

String guestNearbyRestaurantsUrl(double latitude, double longitude,
    String postalCode, int page, int size, String searchTerm) {
  return 'api/public/find?latitude=$latitude&longitude=$longitude&radius=100&postalCode=$postalCode&searchTerm=$searchTerm&page=$page&size=$size';
}

const addressSave = 'api/addresses/save';

const baseUrl =
    'https://api-service.happybush-7c5a2823.centralindia.azurecontainerapps.io/api/';

// notifications
String getNotificationsUrl(int pageNo, int pageSize) {
  return 'order/usernotification/user/list?pageNo=$pageNo&pageSize=$pageSize';
}

const clearAllNotificationsUrl = 'order/usernotification/clear-all';

String getMenuByRestaurantIdUrl(
    String restaurantId, String search, int page, int size) {
  return 'product/api/products/filter?businessId=$restaurantId&attributeValue=Online&attributeValue=DineIN%26Online%26TakeAway&keyword=$search&page=$page&size=$size';
}

String guestMenuByRestaurantIdUrl(int restaurantId) {
  return 'product/api/public/restaurant/$restaurantId';
}

String getRestaurantsByProductNameUrl(String productName, double latitude,
    double longitude, String postalcode, int page, int size) {
  return 'product/api/products/nearby-search?latitude=$latitude&longitude=$longitude&radius=20&postalCode=$postalcode&page=$page&size=$size&searchTerm=$productName&categoryName=Restaurant';
}

String orderHistoryUrl(int page, int size, String searchQuery) {
  return 'order/api/orders/history?page=$page&size=$size&sortBy=createdDate&direction=DESC&query=$searchQuery';
}

const createCartUrl = 'order/api/carts/create';
const getCartUrl = 'order/api/carts/get';
const clearCartUrl = 'order/api/carts/clear';
const productsAddToCartUrl = 'order/api/carts/items';
const saveAddressUrl = 'usermgmt/api/addresses/save';
const getAddressUrl = 'api/addresses/all';
const paymentUrl = 'order/payments/process';
const paymentReFund = 'order/payments/refund';
const paymentRefundStatus = 'order/payments/refunds';
const createOrderUrl = 'order/api/orders/create';
const reOrderUrl = 'order/api/orders/reorder';
const deleteAddressUrl = 'usermgmt/api/addresses';
const defaultAddressUrl = 'usermgmt/api/addresses/setdefaultAddress';
const addressSavetoCartUrl = 'order/api/carts/address?addressId';

// FIX: paymentRefundHistory was an empty string — marked as TODO until the endpoint is known.
const paymentRefundHistory = ''; // TODO: Set the correct refund history endpoint

const restaurantOffersUrl =
    'product/api/offers/list?active=true&page=0&size=100';
String validateOfferUrl(String offerId) {
  return 'order/offers/$offerId/validate';
}

const ratingReviewUrl = 'product/internal/reviews';
const createComplaintUrl = 'order/api/orders/complaints';
const checkoutUrl = 'order/api/orders/estimate-amount';

String updateCartItemsUrl(String cartId) {
  return 'order/api/carts/items/$cartId';
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

const _isProduction =
    bool.fromEnvironment('IS_PRODUCTION', defaultValue: false);

const _razorPayTestKey =
    String.fromEnvironment('RAZORPAY_TEST_KEY', defaultValue: 'rzp_test_RsEtePJVg5vbk9');
const _razorPayTestSecret =
    String.fromEnvironment('RAZORPAY_TEST_SECRET', defaultValue: 'U7RLFFnNceIHKyMtuYJSlkQ5');

const _razorPayLiveKey =
    String.fromEnvironment('RAZORPAY_KEY', defaultValue: '');
const _razorPayLiveSecret =
    String.fromEnvironment('RAZORPAY_SECRET', defaultValue: '');

/// Active Razorpay key — test in dev, live in production.
const razorPayKey = _isProduction ? _razorPayLiveKey : _razorPayTestKey;

/// Active Razorpay secret — test in dev, live in production.
const razorPaySecret = _isProduction ? _razorPayLiveSecret : _razorPayTestSecret;
