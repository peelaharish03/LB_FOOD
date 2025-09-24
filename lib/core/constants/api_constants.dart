//usermanagement
//dev//
// const baseUrl2 = 'https://skillrat.com/usermgmt/';
//prod//
const baseUrl2 = 'https://kovela.app/usermgmt/';

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

//local_basket dev
// const baseUrl = 'https://skillrat.com/';
//local_basket prod
const baseUrl = 'https://kovela.app/';

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
const paymentRefundHistory = '';
const restaurantOffersUrl =
    'product/api/offers/list?businessId=0&active=true&page=0&size=100';
const validateOfferUrl = 'order/offers/102/validate';

String updateCartItemsUrl(String cartId) {
  return 'order/api/carts/items/$cartId';
}

String deleteCartItemsUrl(String cartId) {
  return 'order/api/carts/items/$cartId';
}
