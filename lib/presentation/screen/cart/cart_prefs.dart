import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences access used by [CartScreen].
///
/// Groups the two sets of keys the cart touches — the "offer flow" flags that
/// drive the sticky single-item coupon behaviour, and the persisted delivery
/// address — so the screen keeps only UI logic and the exact same key strings
/// aren't repeated a dozen times inline.
class CartPrefs {
  CartPrefs._();

  // Offer-flow keys.
  static const _kIsOfferFlow = 'is_offer_flow';
  static const _kOfferId = 'offer_id';
  static const _kOfferCoupon = 'offer_coupon';
  static const _kOfferStartedAt = 'offer_started_at';
  static const _kOfferApplied = 'offer_applied';

  // Delivery-address keys.
  static const _kDeliveryAddress = 'delivery_address';
  static const _kDeliveryAddressId = 'delivery_address_id';

  // Selected payment method, stored together with the cart id it was picked
  // for. It survives leaving/re-entering the cart screen and only stops
  // applying once the cart itself changes (a new cart id).
  static const _kPaymentMethod = 'cart_payment_method';
  static const _kPaymentMethodCartId = 'cart_payment_method_cart_id';

  static const defaultAddressLabel = 'Add Address';

  /// The payment method saved for [cartId], or null when nothing was saved or
  /// it belongs to a different (older) cart.
  static Future<String?> readPaymentMethod(String cartId) async {
    final prefs = await SharedPreferences.getInstance();
    final storedCartId = prefs.getString(_kPaymentMethodCartId);
    if (storedCartId == null || storedCartId != cartId) return null;
    final method = prefs.getString(_kPaymentMethod)?.trim();
    return (method == null || method.isEmpty) ? null : method;
  }

  static Future<void> savePaymentMethod(String cartId, String method) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPaymentMethodCartId, cartId);
    await prefs.setString(_kPaymentMethod, method);
  }

  static Future<void> clearPaymentMethod() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kPaymentMethod);
    await prefs.remove(_kPaymentMethodCartId);
  }

  /// Clears the transient offer-flow keys but keeps the sticky
  /// `offer_applied` flag (used after validating an offer).
  static Future<void> clearOfferFlow() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kIsOfferFlow);
    await prefs.remove(_kOfferId);
    await prefs.remove(_kOfferCoupon);
    await prefs.remove(_kOfferStartedAt);
  }

  /// Clears every offer key, including the sticky `offer_applied` flag.
  static Future<void> clearOfferFlowAndApplied() async {
    await clearOfferFlow();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kOfferApplied);
  }

  static Future<void> removeOfferApplied() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kOfferApplied);
  }

  static Future<void> setOfferApplied(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value) {
      await prefs.setBool(_kOfferApplied, true);
    } else {
      await prefs.remove(_kOfferApplied);
    }
  }

  static Future<bool> isOfferApplied() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kOfferApplied) ?? false;
  }

  static Future<OfferFlowFlags> readOfferFlow() async {
    final prefs = await SharedPreferences.getInstance();
    return OfferFlowFlags(
      isOfferFlow: prefs.getBool(_kIsOfferFlow) ?? false,
      stickyApplied: prefs.getBool(_kOfferApplied) ?? false,
      offerId: (prefs.getString(_kOfferId) ?? '').trim(),
    );
  }

  static Future<SavedAddress> readDeliveryAddress() async {
    final prefs = await SharedPreferences.getInstance();
    return SavedAddress(
      address: prefs.getString(_kDeliveryAddress) ?? defaultAddressLabel,
      addressId: prefs.getString(_kDeliveryAddressId),
    );
  }

  static Future<void> saveDeliveryAddress(
    String address, {
    String? addressId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kDeliveryAddress, address);
    if (addressId != null && addressId.isNotEmpty) {
      await prefs.setString(_kDeliveryAddressId, addressId);
    } else {
      await prefs.remove(_kDeliveryAddressId);
    }
  }

  static Future<void> clearDeliveryAddress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kDeliveryAddress);
    await prefs.remove(_kDeliveryAddressId);
  }
}

class OfferFlowFlags {
  const OfferFlowFlags({
    required this.isOfferFlow,
    required this.stickyApplied,
    required this.offerId,
  });

  final bool isOfferFlow;
  final bool stickyApplied;
  final String offerId;
}

class SavedAddress {
  const SavedAddress({required this.address, required this.addressId});

  final String address;
  final String? addressId;
}
