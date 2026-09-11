import 'package:local_basket/presentation/cubit/authentication/currentcustomer/get/current_customer_cubit.dart';
import 'package:local_basket/presentation/cubit/authentication/currentcustomer/get/current_customer_state.dart';
import 'package:local_basket/data/model/cart/getCart/getCart_model.dart';
import 'package:local_basket/data/model/cart/eligiblePromotions/eligiblePromotions_model.dart';
import 'package:local_basket/data/model/payment/checkout_model.dart';
import 'package:local_basket/data/model/payment/deliveryModes/delivery_modes_model.dart';
import 'package:local_basket/presentation/cubit/cart/eligiblePromotions/eligiblePromotions_cubit.dart';
import 'package:local_basket/presentation/cubit/cart/eligiblePromotions/eligiblePromotions_state.dart';
import 'package:local_basket/presentation/cubit/payment/deliveryModes/delivery_modes_cubit.dart';
import 'package:local_basket/presentation/cubit/payment/deliveryModes/delivery_modes_state.dart';
import 'package:local_basket/presentation/screen/widgets/cart/payment_method_dropdown.dart';
import 'package:local_basket/presentation/cubit/offers/restaurant_offers/validate_offers/validate_offer_cubit.dart';
import 'package:local_basket/presentation/cubit/offers/restaurant_offers/validate_offers/validate_offer_state.dart';
import 'package:local_basket/presentation/cubit/payment/checkout/checkout_cubit.dart';
import 'package:local_basket/presentation/cubit/payment/checkout/checkout_state.dart';
import 'package:local_basket/presentation/cubit/restaurants/getNearbyRestaurants/getNearByrestarants_cubit.dart';
import 'package:local_basket/presentation/cubit/restaurants/getNearbyRestaurants/getNearByrestarants_state.dart';
import 'package:local_basket/presentation/screen/widgets/cart/address_card.dart';
import 'package:local_basket/presentation/screen/widgets/cart/cart_item_card.dart';
import 'package:local_basket/presentation/screen/widgets/cart/checkout_bottom_bar.dart';
import 'package:local_basket/presentation/screen/widgets/cart/cart_options_section.dart';
import 'package:local_basket/presentation/screen/widgets/cart/empty_cart_view.dart';
import 'package:local_basket/presentation/screen/cart/cart_prefs.dart';
import 'package:local_basket/presentation/screen/cart/razorpay_checkout_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_basket/core/constants/colors.dart';
import 'package:local_basket/components/custom_snackbar.dart';
import 'package:local_basket/components/custom_topbar.dart';
import 'package:local_basket/presentation/cubit/cart/getCart/getCart_cubit.dart';
import 'package:local_basket/presentation/cubit/cart/getCart/getCart_state.dart';
import 'package:local_basket/presentation/cubit/address/getAddress/getAddress_cubit.dart';
import 'package:local_basket/presentation/cubit/address/getAddress/getAddress_state.dart';
import 'package:local_basket/presentation/cubit/cart/productsAddToCart/productsAddtoCart_cubit.dart';
import 'package:local_basket/presentation/cubit/cart/productsAddToCart/productsAddtoCart_state.dart';
import 'package:local_basket/presentation/cubit/cart/updateCartItems/updateCartItems_cubit.dart';
import 'package:local_basket/presentation/cubit/cart/updateCartItems/updateCartItems_state.dart';
import 'package:local_basket/presentation/cubit/cart/applyCoupon/applyCoupon_cubit.dart';
import 'package:local_basket/presentation/cubit/cart/applyCoupon/applyCoupon_state.dart';
import 'package:local_basket/presentation/screen/address/address_screen.dart';
import 'package:local_basket/presentation/screen/dashboard/dashboard_screen.dart';
import 'package:local_basket/presentation/screen/order/orderSuccess_screen.dart';
// FIX: Import Razorpay keys from api_constants instead of hardcoding them here.
import 'package:local_basket/core/constants/api_constants.dart';
import 'package:local_basket/core/constants/global_exception_handler.dart';
import 'package:local_basket/core/utils/address_formatter.dart';

class CartScreen extends StatefulWidget {
  final int? orderId;
  final List<Map<String, dynamic>>? cartItems;
  final Function(bool)? onBottomSheetVisibilityChanged;
  final Widget? customCheckoutButton;
  const CartScreen({
    super.key,
    this.orderId,
    this.cartItems,
    this.onBottomSheetVisibilityChanged,
    this.customCheckoutButton,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late Razorpay _razorpay;

  final TextEditingController notesController = TextEditingController();

  final TextEditingController couponController = TextEditingController();
  bool _isCouponApplied = false;

  bool _offerValidationInFlight = false;
  DateTime? _lastOfferValidationAt;

  final Map<String, int> cart = {};
  final List<Map<String, dynamic>> selectedItems = [];
  String? cartId;
  double? _pendingCheckoutAmount;
  String? _processedRazorpayPaymentId;
  bool loading = false;
  String selectedAddress = "Add Address";
  String? _selectedAddressId;
  bool selfOrder = false;

  static const double _defaultDeliveryCharge = 30.0;

  double _subtotal = 0.0;
  double _deliveryCharge = 0.0;
  double _grandTotal = 0.0;
  bool _checkoutInFlight = false;

  // Delivery charge, tax, platform fee, total discount and grand total
  // exactly as reported on the cart itself (`deliveryCharge` / `totalTax` /
  // `platformFee` / `totalDiscount` / `grandTotal`) — the single source of
  // truth for the checkout bottom bar's breakdown dropdown and its Total.
  double _cartDeliveryCharge = 0.0;
  double _cartTaxTotal = 0.0;
  double _cartPlatformFee = 0.0;
  double _cartTotalDiscount = 0.0;
  double _cartGrandTotal = 0.0;

  // Price breakdown from the checkout-preview endpoint (`/api/carts/checkout`).
  // This is the only response that reflects the *chosen payment method* — the
  // plain getCart figures don't move when the cart item's `paymentMethod`
  // changes, but the preview applies the COD fee / online discount / delivery
  // waiver. Null until a preview runs; the bottom bar falls back to the
  // getCart values (`_cart*`) whenever a field is absent here.
  double? _previewItemsTotal;
  double? _previewTaxTotal;
  double? _previewDeliveryCharge;
  double? _previewGrandTotal;

  bool _chargesPreviewInFlight = false;

  // Promo codes (promotions/eligible API) — when the cart has any eligible
  // promo code, Cash on Delivery becomes available and delivery charges are
  // waived for the order, same as the legacy single-item coupon flow.
  List<EligiblePromotion> _eligiblePromotions = [];
  bool _promotionsLoading = false;
  bool _promotionsFetched = false;
  String? _selectedPromoCode;
  String? _promotionsFetchedForCartId;

  // The coupon code the cart itself currently carries, from the last getCart
  // response. This is the source of truth for what the promo field shows — it
  // survives an eligible-promotions refresh even when the applied code is no
  // longer returned in the "eligible" list.
  String? _cartCouponCode;

  // True while a cart-level coupon apply / remove call is in flight — shown as
  // a spinner on the promo field so the pick doesn't look ignored.
  bool _promoApplying = false;

  bool get _hasEligiblePromotions => _eligiblePromotions.isNotEmpty;

  // Payment method / delivery mode pickers. The payment picker is a fixed
  // two-choice control (COD / online); the delivery-mode list still comes
  // from its cubit. Only the current selection is kept as local state. The
  // selected payment method's `code` goes to checkout as `paymentMethod`,
  // the delivery mode's `code` as `shippingMethod`.
  static const String _codPaymentCode = PaymentMethodDropdown.codCode;
  static const String _onlinePaymentCode = PaymentMethodDropdown.onlineCode;

  // Starts null so the buyer always makes an explicit choice — never
  // auto-defaulted. Once picked it is kept in local state and shown on screen
  // until the cart itself changes (a new cart id, e.g. the cart was cleared
  // and a fresh one started).
  String? _selectedPaymentMethod;
  String? _selectedDeliveryMode;

  // The cart id the current `_selectedPaymentMethod` belongs to. When a
  // getCart response carries a different id the payment choice is dropped and
  // re-seeded from that cart.
  String? _paymentMethodCartId;

  /// Maps whatever the cart reports in `paymentMethod` back onto one of the
  /// two picker codes (COD / online), so a previously chosen method is
  /// re-selected when the screen is reopened.
  String? _normalizePaymentMethod(String? raw) {
    final value = raw?.trim().toUpperCase();
    if (value == null || value.isEmpty) return null;
    if (value == _codPaymentCode ||
        value.contains('COD') ||
        value.contains('CASH')) {
      return _codPaymentCode;
    }
    if (value == _onlinePaymentCode ||
        value.contains('RAZOR') ||
        value.contains('ONLINE') ||
        value.contains('PREPAID')) {
      return _onlinePaymentCode;
    }
    return null;
  }

  /// Grand total to show on the bottom bar. Prefers the cart's own
  /// `grandTotal`; if the backend hasn't computed it yet (0 before a payment
  /// method / address is set) falls back to a local sum of the cart charges.
  double get _effectiveGrandTotal {
    if (_cartGrandTotal > 0) return _cartGrandTotal;
    final computed = _subtotal +
        _cartDeliveryCharge +
        _cartTaxTotal +
        _cartPlatformFee -
        _cartTotalDiscount;
    return computed > 0 ? computed : _subtotal;
  }

  // Figures shown on the checkout bottom bar. Each prefers the payment-method
  // aware checkout-preview value and falls back to the plain cart value when
  // the preview hasn't produced one. Delivery charge deliberately accepts a
  // preview value of 0 (a genuine waiver) — hence the null check rather than
  // `> 0`. Platform fee and discount have no preview equivalent, so those
  // stay on the cart figures.
  double get _displayItemTotal =>
      (_previewItemsTotal != null && _previewItemsTotal! > 0)
          ? _previewItemsTotal!
          : _subtotal;

  double get _displayDeliveryCharge =>
      _previewDeliveryCharge ?? _cartDeliveryCharge;

  double get _displayTax =>
      (_previewTaxTotal != null && _previewTaxTotal! > 0)
          ? _previewTaxTotal!
          : _cartTaxTotal;

  double get _displayGrandTotal =>
      (_previewGrandTotal != null && _previewGrandTotal! > 0)
          ? _previewGrandTotal!
          : _effectiveGrandTotal;

  // True while a just-picked payment method is being persisted onto the cart
  // and the promo/charges preview is being refreshed for it — shown as a
  // spinner on the payment field itself so the pick doesn't look ignored.
  bool _paymentContextSyncing = false;

  List<DeliveryMode> _deliveryModesOf(DeliveryModesState state) =>
      state is DeliveryModesLoaded ? state.model.activeModes : const [];

  /// `shippingMethod` for checkout — the picked mode, else the first
  /// available mode, else the STANDARD fallback.
  String get _shippingMethod {
    final modes = _deliveryModesOf(context.read<DeliveryModesCubit>().state);
    final code = _selectedDeliveryMode;
    if (code != null && modes.any((m) => m.checkoutCode == code)) return code;
    if (modes.isNotEmpty) return modes.first.checkoutCode;
    return 'STANDARD';
  }

  void _applyFlatCharges() {
    final hasItems = selectedItems.isNotEmpty;
    final waiveDelivery = _isCouponApplied || _hasEligiblePromotions;
    _deliveryCharge = (hasItems && !waiveDelivery) ? _defaultDeliveryCharge : 0;
    _grandTotal = _subtotal + _deliveryCharge;
  }

  /// Fetches the eligible promo codes for the current cart.
  ///
  /// [force] bypasses the "already fetched for this cart + payment method"
  /// guard. [background] keeps the currently shown promo list visible while
  /// the request is in flight (no loading spinner) — used when the payment
  /// method changes, so the dropdown just swaps to the latest values once
  /// the response arrives.
  Future<void> _maybeFetchEligiblePromotions({
    bool force = false,
    bool background = false,
  }) async {
    if (selectedItems.isEmpty) {
      if (_eligiblePromotions.isNotEmpty || _promotionsFetched) {
        setState(() {
          _eligiblePromotions = [];
          _promotionsFetched = false;
          _selectedPromoCode = null;
          _cartCouponCode = null;
        });
      }
      return;
    }

    // Promo codes can only be picked once a payment method is chosen, and the
    // eligible-promotions list is re-fetched whenever that choice changes.
    if (_selectedPaymentMethod == null) return;

    final activeCartId = await _ensureCartId();
    if (!mounted) return;
    if (!_hasValidCartId(activeCartId)) return;

    final fetchKey = '$activeCartId|$_selectedPaymentMethod';
    if (!force && _promotionsFetchedForCartId == fetchKey) return;
    _promotionsFetchedForCartId = fetchKey;

    if (!background) setState(() => _promotionsLoading = true);
    debugPrint(
      '[Promotions] fetch eligible: cartId=$activeCartId, '
      'paymentMethod=$_selectedPaymentMethod, background=$background',
    );
    await context.read<EligiblePromotionsCubit>().fetchEligiblePromotions({
      "cartId": activeCartId,
      "b2bUnitId": defaultB2bUnitId,
      "paymentMethod": _selectedPaymentMethod,
    });
  }

  /// Called when the buyer changes the payment method — persists the choice
  /// onto the cart, then re-runs the eligible-promotions API and refreshes
  /// the promo dropdown and the checkout charge preview.
  ///
  /// The eligible-promotions call is made twice on purpose: once right away so
  /// the dropdown reacts immediately, and again after the payment method has
  /// been written onto the cart — the backend sometimes returns extra promo
  /// codes only once the cart itself carries the new payment method.
  Future<void> _onPaymentMethodChanged(String? code) async {
    if (code == _selectedPaymentMethod) return;
    // The previously picked promo may no longer apply to the new method — drop
    // it from the cart via the coupon endpoint before switching.
    final promoToClear = _selectedPromoCode;
    final activeCartId = await _ensureCartId();
    if (!mounted) return;

    setState(() {
      _selectedPaymentMethod = code;
      _paymentMethodCartId = _hasValidCartId(activeCartId)
          ? activeCartId
          : (cartId ?? _paymentMethodCartId);
      _selectedPromoCode = null;
      _paymentContextSyncing = true;
    });

    // Persist the choice locally, keyed to this cart, so it's still shown
    // after leaving and re-entering the cart screen — until the cart changes.
    if (_hasValidCartId(_paymentMethodCartId)) {
      if (code != null && code.isNotEmpty) {
        await CartPrefs.savePaymentMethod(_paymentMethodCartId!, code);
      } else {
        await CartPrefs.clearPaymentMethod();
      }
    }
    if (!mounted) return;

    try {
      if (promoToClear != null && _hasValidCartId(activeCartId)) {
        await context.read<ApplyCouponCubit>().removeCoupon(
          activeCartId!,
          promoToClear,
        );
        if (!mounted) return;
      }
      _maybeFetchEligiblePromotions(force: true, background: true);
      await _persistCartContext();
      if (!mounted) return;
      _maybeFetchEligiblePromotions(force: true, background: true);
      await _refreshChargesPreview();
    } finally {
      if (mounted) setState(() => _paymentContextSyncing = false);
    }
  }

  /// Restores the payment method the buyer saved for this cart (from prefs),
  /// falling back to whatever the cart itself carries. Runs after every
  /// getCart. Does nothing while a pick is being written, or when a pick for
  /// this same cart is already on screen.
  Future<void> _syncPaymentMethodForCart(GetCartModel loadedCart) async {
    if (_paymentContextSyncing) return;
    final loadedCartId = loadedCart.id;
    if (!_hasValidCartId(loadedCartId)) return;

    if (_selectedPaymentMethod != null &&
        _paymentMethodCartId == loadedCartId) {
      return;
    }

    final stored = await CartPrefs.readPaymentMethod(loadedCartId!);
    if (!mounted) return;

    final resolved =
        stored ?? _normalizePaymentMethod(loadedCart.paymentMethod);

    if (resolved == _selectedPaymentMethod &&
        _paymentMethodCartId == loadedCartId) {
      return;
    }

    setState(() {
      _selectedPaymentMethod = resolved;
      _paymentMethodCartId = loadedCartId;
    });

    if (resolved != null) {
      _maybeFetchEligiblePromotions();
      _refreshChargesPreview();
    }
  }

  /// Called when the buyer picks (or clears) a promo code from the cart
  /// screen. The promo code is applied to / removed from the cart through the
  /// dedicated cart-level coupon endpoints
  /// (`POST` / `DELETE /api/carts/{cartId}/coupon?code=…`) — it is no longer
  /// piggy-backed on the add-item / update-item cart calls. Afterwards the
  /// cart is refetched and the checkout charge preview refreshed.
  Future<void> _onPromoCodeChanged(String? code) async {
    final newCode = (code == null || code.trim().isEmpty) ? null : code.trim();
    final previousCode = _selectedPromoCode;
    if (newCode == previousCode) return;
    if (_promoApplying) return;

    final activeCartId = await _ensureCartId();
    if (!mounted) return;
    if (!_hasValidCartId(activeCartId)) {
      CustomSnackbars.showErrorSnack(
        context: context,
        title: "Error",
        message: "Cart id not found",
      );
      return;
    }

    setState(() {
      _promoApplying = true;
      _selectedPromoCode = newCode;
    });

    bool ok;
    if (newCode != null) {
      ok = await context.read<ApplyCouponCubit>().applyCoupon(
        activeCartId!,
        newCode,
        context: context,
      );
    } else {
      ok = await context.read<ApplyCouponCubit>().removeCoupon(
        activeCartId!,
        previousCode ?? "",
        context: context,
      );
    }
    if (!mounted) return;

    if (!ok) {
      // Roll back to the previous selection — the listener shows the error.
      setState(() {
        _selectedPromoCode = previousCode;
        _promoApplying = false;
      });
      return;
    }

    await context.read<GetCartCubit>().fetchCart(context);
    if (!mounted) return;
    setState(() => _promoApplying = false);
    _refreshChargesPreview();

    if (newCode != null) {
      CustomSnackbars.showSuccessSnack(
        context: context,
        title: "Promo code applied",
        message: "Successfully added promo code \"$newCode\" to your cart",
        duration: const Duration(seconds: 2),
      );
    } else {
      CustomSnackbars.showInfoSnack(
        context: context,
        title: "Promo code removed",
        message: "The promo code has been removed from your cart",
      );
    }
  }

  /// Pushes the current payment-method / promo-code / shipping-method picks
  /// onto the cart. There is no cart-level update endpoint, so this re-sends
  /// one existing cart line via PUT with the context fields attached, then
  /// refetches the cart to resync totals.
  Future<void> _persistCartContext() async {
    if (_selectedPaymentMethod == null) return;
    if (selectedItems.isEmpty) return;

    final activeCartId = await _ensureCartId();
    if (!mounted || !_hasValidCartId(activeCartId)) {
      debugPrint(
        '[CartContext] no valid cartId (activeCartId=$activeCartId); '
        'skipping persist',
      );
      return;
    }

    final item = selectedItems.first;
    final cartItemId = await _cartItemIdForProduct(item);
    if (!mounted || !_hasValidCartId(cartItemId)) {
      debugPrint(
        '[CartContext] no cart item id for product '
        '${item['productId']} in cart $activeCartId; skipping persist',
      );
      return;
    }

    final quantity =
        cart[item['name']] ?? ((item['quantity'] as num?)?.toInt() ?? 1);
    // NOTE: the promo code is intentionally NOT sent here — it is applied to
    // the cart through the dedicated coupon endpoint in `_onPromoCodeChanged`.
    final payload = <String, dynamic>{
      "quantity": quantity,
      "paymentMethod": _selectedPaymentMethod,
      "shippingMethod": _shippingMethod,
    };

    debugPrint('[CartContext] persist via PUT items/$cartItemId: $payload');
    await context.read<UpdateCartItemsCubit>().updateCartItem(
      payload,
      activeCartId!,
      cartItemId!,
      context,
    );
    if (!mounted) return;
    await context.read<GetCartCubit>().fetchCart(context);
    final refreshed = context.read<GetCartCubit>().state;
    if (refreshed is GetCartLoaded) {
      final c = refreshed.cart;
      debugPrint(
        '[CartContext] after persist, cart refreshed: id=${c.id} '
        'paymentMethod=${c.paymentMethod} deliveryCharge=${c.deliveryCharge} '
        'platformFee=${c.platformFee} grandTotal=${c.grandTotal}',
      );
    } else {
      debugPrint('[CartContext] after persist, GetCartCubit state=$refreshed');
    }
  }

  /// Refreshes the price breakdown (delivery / tax / discount / total) shown
  /// under the collapsible charges section by calling the checkout preview
  /// endpoint — the only source of the applied charges. Needs an address and
  /// a payment method to be chosen first.
  Future<void> _refreshChargesPreview() async {
    if (_chargesPreviewInFlight) return;
    if (selectedItems.isEmpty) return;
    if (_selectedPaymentMethod == null) return;
    if (_selectedAddressId == null || _selectedAddressId!.isEmpty) return;

    final activeCartId = await _ensureCartId();
    if (!mounted || !_hasValidCartId(activeCartId)) return;

    _chargesPreviewInFlight = true;
    try {
      final payload = {
        "cartId": activeCartId,
        "shippingMethod": _shippingMethod,
        "paymentMethod": _selectedPaymentMethod,
        "shippingAddressId": _selectedAddressId ?? "",
        "b2bUnitId": defaultB2bUnitId,
        if (_selectedPromoCode != null) "promoCode": _selectedPromoCode,
      };
      debugPrint('[Checkout] charge preview: $payload');
      await context.read<CheckoutCubit>().fetchCheckout(payload);
    } finally {
      _chargesPreviewInFlight = false;
    }
  }

  @override
  void initState() {
    super.initState();
    _razorpay =
        Razorpay()
          ..on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess)
          ..on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentFailure)
          ..on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);

    context.read<GetCartCubit>().fetchCart(context);
    context.read<DeliveryModesCubit>().fetchDeliveryModes();
    _loadSavedAddress();
    context.read<GetAddressCubit>().fetchAddress(context);
    _initCartItems();
    Future.delayed(const Duration(milliseconds: 300), () {
      _maybeAutoValidateOffer();
      _refreshCheckout();
    });
    () async {
      final applied = await CartPrefs.isOfferApplied();
      if (applied && mounted && getCartItemCount() == 1) {
        setState(() => _isCouponApplied = true);
      }
    }();
  }

  // Refresh checkout from API
  void _refreshCheckout() {
    if (!mounted) return;
    if (selectedItems.isEmpty) {
      setState(() {
        _subtotal = 0;
        _deliveryCharge = 0;
        _grandTotal = 0;
      });
    } else {
      setState(_applyFlatCharges);
    }
  }

  void _onPaymentSuccess(PaymentSuccessResponse response) async {
    debugPrint(
      '[Razorpay] success: paymentId=${response.paymentId}, '
      'orderId=${response.orderId}, signaturePresent=${response.signature != null}',
    );

    // The Razorpay SDK has been known to fire EVENT_PAYMENT_SUCCESS more
    // than once for a single payment; without this guard that would submit
    // the same payment twice and create two orders.
    final paymentId = response.paymentId;
    if (paymentId != null && paymentId == _processedRazorpayPaymentId) {
      debugPrint(
        '[Razorpay] duplicate success callback for $paymentId; ignoring',
      );
      return;
    }
    _processedRazorpayPaymentId = paymentId;

    final payload = {
      "cartId": cartId ?? "",
      "amount": (_pendingCheckoutAmount ?? _grandTotal).toString(),
      "paymentId": response.paymentId ?? "",
      "razorpayOrderId": response.orderId ?? "",
      "razorpaySignature": response.signature ?? "",
      "status": "SUCCESS",
      "b2bUnitId": defaultB2bUnitId,
    };
    debugPrint('[Razorpay] verify-payment (success) payload: $payload');
    setState(() => loading = true);
    final result = await context.read<CheckoutCubit>().verifyPayment(payload);
    if (!mounted) return;
    setState(() => loading = false);

    if (result != null) {
      CustomSnackbars.showSuccessSnack(
        context: context,
        title: 'Success',
        message: 'Payment Successful!',
      );
      CartPrefs.clearOfferFlowAndApplied();
      CartPrefs.clearPaymentMethod();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
          (route) => false,
        );
      });
    }
  }

  void _onPaymentFailure(dynamic response) async {
    if (!mounted) return;

    final failure = response is PaymentFailureResponse ? response : null;

    // The buyer closed the Razorpay sheet without attempting a payment at
    // all (back button / swipe-away) — Razorpay reports this the same way as
    // a real failure, but no payment was ever made, so there is nothing to
    // verify with the backend. Reporting it as a "FAILURE" anyway is what
    // was finalizing the order tied to this cart server-side and left the
    // cart looking cleared on return. Just leave the cart exactly as it was.
    if (failure?.code == Razorpay.PAYMENT_CANCELLED) {
      debugPrint('[Razorpay] cancelled by user before any payment attempt');
      CustomSnackbars.showInfoSnack(
        context: context,
        title: 'Payment Cancelled',
        message: 'You cancelled the payment. Your cart is unchanged.',
      );
      setState(() => loading = false);
      return;
    }

    final failureMessage = RazorpayCheckoutHelper.formatFailure(response);
    debugPrint('[Razorpay] failure: $failureMessage');
    CustomSnackbars.showErrorSnack(
      context: context,
      title: 'Failed',
      message: failureMessage,
    );

    final error = failure?.error;
    final metadata = error?['metadata'];

    final payload = {
      "cartId": cartId ?? "",
      "amount": (_pendingCheckoutAmount ?? _grandTotal).toString(),
      "paymentId": (metadata?['payment_id'] ?? "").toString(),
      "razorpayOrderId": (metadata?['order_id'] ?? "").toString(),
      "razorpaySignature": "",
      "status": "FAILURE",
      "b2bUnitId": defaultB2bUnitId,
    };
    debugPrint('[Razorpay] verify-payment (failure) payload: $payload');
    setState(() => loading = true);
    await context.read<CheckoutCubit>().verifyPayment(payload);
    if (!mounted) return;
    setState(() => loading = false);
  }

  void _onExternalWallet(_) {
    debugPrint('[Razorpay] external wallet selected');
    CustomSnackbars.showInfoSnack(
      context: context,
      title: 'Info',
      message: 'Check payment status later',
    );
    setState(() => loading = false);
  }

  Future<void> _loadSavedAddress() async {
    final saved = await CartPrefs.readDeliveryAddress();
    if (!mounted) return;
    setState(() {
      selectedAddress = saved.address;
      _selectedAddressId = saved.addressId;
    });
  }

  Future<void> _clearSavedAddress() async {
    await CartPrefs.clearDeliveryAddress();
    if (!mounted) return;
    setState(() {
      selectedAddress = "Add Address";
      _selectedAddressId = null;
    });
  }

  Future<void> _maybeAutoValidateOffer() async {
    try {
      final now = DateTime.now();
      if (_lastOfferValidationAt != null &&
          now.difference(_lastOfferValidationAt!).inMilliseconds < 800) {
        return;
      }
      if (_offerValidationInFlight) return;

      final flags = await CartPrefs.readOfferFlow();
      final isOfferFlow = flags.isOfferFlow;
      final stickyApplied = flags.stickyApplied;
      final offerId = flags.offerId;

      final hasExactlyOne = getCartItemCount() == 1;
      if (hasExactlyOne) {
        if (stickyApplied) {
          if (mounted) setState(() => _isCouponApplied = true);
          return;
        }
        if (!isOfferFlow) return;
        if (offerId.isEmpty) return;
        _offerValidationInFlight = true;
        _lastOfferValidationAt = now;
        try {
          await context.read<ValidateOfferCubit>().validateOffer(offerId);
        } finally {
          _offerValidationInFlight = false;
        }
      }
    } catch (_) {}
  }

  Future<void> _saveAddress(String address, {String? addressId}) =>
      CartPrefs.saveDeliveryAddress(address, addressId: addressId);

  String _formatAddress(dynamic content) {
    final item = content.address;
    if (item == null) return '';
    return joinAddressParts([
      item.line1,
      item.line2,
      item.fullText,
      item.city,
      item.state,
      item.country,
      item.postalCode,
    ]);
  }

  void _initCartItems() {
    if (widget.cartItems != null) {
      for (final item in widget.cartItems!) {
        final name = item['name'];
        final quantity = item['quantity'] ?? 0;
        if (name != null && quantity > 0) {
          cart[name] = quantity;
          selectedItems.add(item);
        }
      }
    }
    _seedProvisionalTotals();
  }

  /// Best-effort totals computed from whatever cart data is already known
  /// locally (e.g. `widget.cartItems`, passed in from the screen that opened
  /// the cart) so the checkout bottom bar shows a real number on the very
  /// first frame instead of 0 while the getCart API call is still in
  /// flight — otherwise the first open after adding an item briefly (or, on
  /// a slow connection, not-so-briefly) showed an incorrect total until the
  /// fetch resolved. `_syncCartFromGetCart` overwrites these with the
  /// authoritative server values as soon as that response lands.
  void _seedProvisionalTotals() {
    if (selectedItems.isEmpty) return;
    final itemsTotal = selectedItems.fold<double>(0.0, (sum, item) {
      final totalPrice = (item['totalPrice'] as num?)?.toDouble();
      if (totalPrice != null) return sum + totalPrice;
      final quantity = (item['quantity'] as num?)?.toDouble() ?? 1;
      final unitPrice =
          (item['unitPrice'] as num?)?.toDouble() ??
          (item['price'] as num?)?.toDouble() ??
          0;
      return sum + (unitPrice * quantity);
    });
    if (itemsTotal <= 0) return;
    _subtotal = itemsTotal;
    _cartDeliveryCharge = _defaultDeliveryCharge;
    _cartGrandTotal = _subtotal + _cartDeliveryCharge;
  }

  void _syncCartFromGetCart(GetCartModel loadedCart) {
    cart.clear();
    selectedItems.clear();

    for (final cartItem in loadedCart.cartItems) {
      final quantity = cartItem.quantity ?? 0;
      final name =
          (cartItem.productName ?? cartItem.productCode ?? '')
              .toString()
              .trim();

      if (name.isEmpty || quantity <= 0) continue;

      final productId = cartItem.productId?.toString();
      final unitPrice =
          cartItem.unitPrice ??
          cartItem.price ??
          (quantity > 0 && cartItem.totalPrice != null
              ? cartItem.totalPrice! / quantity
              : cartItem.totalPrice) ??
          0;

      cart[name] = quantity;
      selectedItems.add({
        'id': productId,
        'cartItemId': cartItem.id,
        'productId': productId,
        'productCode': cartItem.productCode,
        'name': name,
        'quantity': quantity,
        'price': unitPrice,
        'unitPrice': cartItem.unitPrice,
        'totalPrice': cartItem.totalPrice,
        'discountPrice': cartItem.discountPrice,
        'taxAmount': cartItem.taxAmount,
        'media': cartItem.media.map((media) => media.toJson()).toList(),
      });
    }

    // Sum the items' own totalPrice rather than trusting the cart's subTotal
    // field directly, so the total shown always matches what the items list
    // displays even if the cart response's aggregate field lags behind.
    final itemsTotalPrice = selectedItems.fold<double>(
      0.0,
      (sum, item) => sum + ((item['totalPrice'] as num?)?.toDouble() ?? 0.0),
    );
    _subtotal =
        itemsTotalPrice > 0
            ? itemsTotalPrice
            : (loadedCart.subTotal ?? 0).toDouble();
    _cartDeliveryCharge = (loadedCart.deliveryCharge ?? 0).toDouble();
    _cartTaxTotal = (loadedCart.totalTax ?? 0).toDouble();
    _cartPlatformFee = (loadedCart.platformFee ?? 0).toDouble();
    _cartTotalDiscount = (loadedCart.totalDiscount ?? 0).toDouble();
    _cartGrandTotal = (loadedCart.grandTotal ?? 0).toDouble();

    // Payment method restore is handled separately (async, from prefs) in
    // `_syncPaymentMethodForCart` — it's the buyer's own choice, never
    // auto-defaulted, and must not be touched here.

    // Reflect a coupon already applied to the cart server-side in the promo
    // dropdown — the cart's own `couponCode` is the source of truth. Never
    // clobber a pick the buyer is mid-applying (`_promoApplying`).
    final appliedCoupon = loadedCart.couponCode?.trim();
    _cartCouponCode =
        (appliedCoupon != null && appliedCoupon.isNotEmpty)
            ? appliedCoupon
            : null;
    if (!_promoApplying) {
      _selectedPromoCode = _cartCouponCode;
    }
    debugPrint(
      '[Cart] synced cartId=${loadedCart.id} '
      'paymentMethod=${loadedCart.paymentMethod} '
      'subtotal=$_subtotal deliveryCharge=$_cartDeliveryCharge '
      'platformFee=$_cartPlatformFee totalDiscount=$_cartTotalDiscount '
      'grandTotal=$_cartGrandTotal',
    );
    _applyFlatCharges();
  }

  Future<String?> _ensureCartId() async {
    final currentCartId = cartId;
    if (_hasValidCartId(currentCartId)) {
      return currentCartId;
    }

    final prefs = await SharedPreferences.getInstance();
    final storedCartId = prefs.get('cart_id')?.toString();
    if (_hasValidCartId(storedCartId)) {
      if (mounted) setState(() => cartId = storedCartId);
      return storedCartId;
    }

    final cartState = context.read<GetCartCubit>().state;
    if (cartState is GetCartLoaded) {
      final loadedCartId = cartState.cart.id;
      if (_hasValidCartId(loadedCartId)) {
        if (mounted) setState(() => cartId = loadedCartId);
        return loadedCartId;
      }
    }

    await context.read<GetCartCubit>().fetchCart(context);
    final refreshedCartState = context.read<GetCartCubit>().state;
    if (refreshedCartState is GetCartLoaded) {
      final refreshedCartId = refreshedCartState.cart.id;
      if (_hasValidCartId(refreshedCartId)) {
        if (mounted) setState(() => cartId = refreshedCartId);
        return refreshedCartId;
      }
    }

    return null;
  }

  bool _hasValidCartId(String? id) {
    final normalized = id?.trim();
    return normalized != null &&
        normalized.isNotEmpty &&
        normalized != '0' &&
        normalized.toLowerCase() != 'null';
  }

  /// Buyer contact details passed to Razorpay's `prefill`. Needs the customer
  /// cubit, so it stays on the screen; the string tidying lives in
  /// [RazorpayCheckoutHelper].
  Map<String, dynamic> _razorpayPrefill() {
    final prefill = <String, dynamic>{};

    try {
      final state = context.read<CurrentCustomerCubit>().state;
      if (state is CurrentCustomerLoaded) {
        final customer = state.currentCustomerModel;
        final name =
            RazorpayCheckoutHelper.trimmedOrNull(
              [customer.firstName, customer.lastName]
                  .whereType<String>()
                  .map((part) => part.trim())
                  .where((part) => part.isNotEmpty)
                  .join(' '),
            ) ??
            RazorpayCheckoutHelper.trimmedOrNull(customer.username);
        final email = RazorpayCheckoutHelper.trimmedOrNull(customer.email);
        final contact = RazorpayCheckoutHelper.formattedContact(customer.mobile);

        if (name != null) prefill['name'] = name;
        if (email != null) prefill['email'] = email;
        if (contact != null) prefill['contact'] = contact;
      }
    } catch (_) {}

    return prefill;
  }

  String? _productIdForPayload(Map<String, dynamic> item) {
    final productId = (item['productId'] ?? item['id'])?.toString();
    if (productId == null || productId.isEmpty || productId == '0') {
      return null;
    }
    return productId;
  }

  Map<String, dynamic>? _singleItemCartPayload(
    Map<String, dynamic> item,
    int quantity,
  ) {
    final productId = _productIdForPayload(item);
    if (productId == null) return null;
    return {
      "productId": productId,
      "quantity": quantity,
      ..._selectedCartContextFields(),
    };
  }

  /// The buyer's current picks (payment method, shipping method) that ride
  /// along with the add-items-to-cart request. Each key is only included once a
  /// value is available, so nothing changes until the user actually makes a
  /// choice. The promo code is deliberately excluded — it is applied to the
  /// cart via the dedicated coupon endpoint in `_onPromoCodeChanged`.
  Map<String, dynamic> _selectedCartContextFields() {
    final fields = <String, dynamic>{};

    final paymentMethod = _selectedPaymentMethod?.trim();
    if (paymentMethod != null && paymentMethod.isNotEmpty) {
      fields["paymentMethod"] = paymentMethod;
    }

    final shippingMethod = _shippingMethod;
    if (shippingMethod.isNotEmpty) {
      fields["shippingMethod"] = shippingMethod;
    }

    return fields;
  }

  String? _cartItemIdFromState(dynamic productId) {
    final cartState = context.read<GetCartCubit>().state;
    if (cartState is! GetCartLoaded) return null;

    for (final cartItem in cartState.cart.cartItems) {
      if (cartItem.productId?.toString() == productId?.toString()) {
        return cartItem.id;
      }
    }
    return null;
  }

  Future<String?> _cartItemIdForProduct(Map<String, dynamic> item) async {
    final existingItemId =
        (item['cartItemId'] ?? item['cartItemID'] ?? item['lineItemId'])
            ?.toString();
    if (_hasValidCartId(existingItemId)) return existingItemId;

    final productId = item['productId'] ?? item['id'];
    var cartItemId = _cartItemIdFromState(productId);
    if (_hasValidCartId(cartItemId)) return cartItemId;

    await context.read<GetCartCubit>().fetchCart(context);
    cartItemId = _cartItemIdFromState(productId);
    return _hasValidCartId(cartItemId) ? cartItemId : null;
  }

  Future<void> _updateExistingCartItemQuantity(
    String activeCartId,
    Map<String, dynamic> item,
    int quantity,
  ) async {
    final cartItemId = await _cartItemIdForProduct(item);
    if (!_hasValidCartId(cartItemId)) {
      debugPrint('Cart item id unavailable. Skipping cart item update.');
      return;
    }

    await context.read<UpdateCartItemsCubit>().updateCartItem(
      {"quantity": quantity},
      activeCartId,
      cartItemId!,
      context,
    );
  }

  int getCartItemCount() => cart.values.fold(0, (sum, q) => sum + q);

  Future<CheckoutModel?> _submitCartCheckout(String paymentMethod) async {
    final activeCartId = await _ensureCartId();
    if (!mounted) return null;
    print(activeCartId);
    if (!_hasValidCartId(activeCartId)) {
      CustomSnackbars.showErrorSnack(
        context: context,
        title: 'ERROR',
        message: 'Cart id not found',
      );
      return null;
    }

    final payload = {
      "cartId": activeCartId,
      "shippingMethod": _shippingMethod,
      "paymentMethod": paymentMethod,
      "shippingAddressId": _selectedAddressId ?? "",
      "b2bUnitId": defaultB2bUnitId,
      if (_selectedPromoCode != null) "promoCode": _selectedPromoCode,
    };

    debugPrint(
      '[Checkout] submit: paymentMethod=$paymentMethod, cartId=$activeCartId',
    );
    // Step 1: move the cart into checkout.
    final checkout = await context.read<CheckoutCubit>().fetchCheckout(payload);
    if (checkout == null) {
      debugPrint('[Checkout] failed: checkout response is null');
      return null;
    }

    // Step 2: initiate — this is what actually returns the Razorpay
    // order id/key to pay with.
    final initiated = await context.read<CheckoutCubit>().initiateCheckout(
      payload,
    );

    if (initiated != null) {
      _pendingCheckoutAmount =
          initiated.totalAmount?.toDouble() ??
          initiated.data?.grandTotal?.toDouble() ??
          checkout.totalAmount?.toDouble() ??
          _grandTotal;
      debugPrint(
        '[Checkout] initiated: orderId=${initiated.orderId}, '
        'razorpayOrderId=${initiated.razorpayOrderId}, '
        'totalAmount=${initiated.totalAmount}, '
        'grandTotal=${initiated.data?.grandTotal}, '
        'key=${initiated.razorpayKeyId == null ? null : RazorpayCheckoutHelper.maskKey(initiated.razorpayKeyId!)}',
      );
    } else {
      debugPrint('[Checkout] initiate failed: response is null');
    }

    return initiated;
  }

  // The cart's store must be within this many km of the buyer's current
  // location for checkout to be allowed — the same radius the dashboard uses
  // to list nearby stores.
  static const double _storeDeliveryRadiusKm = 3.0;

  /// Before checkout, confirms the store the cart belongs to still delivers to
  /// where the buyer is *now*. Items may have been added while near the store
  /// and the buyer since travelled away — that order is blocked with a popup
  /// instead of failing later at the payment step.
  ///
  /// It re-queries the nearby-stores API (radius [_storeDeliveryRadiusKm]) for
  /// the buyer's current location: if the cart's store comes back, the backend
  /// has confirmed it's in range; if it doesn't, the buyer is outside its
  /// delivery area.
  ///
  /// Fails open: if the buyer's location or the store list can't be
  /// determined, checkout is allowed and the backend stays the final
  /// authority — only a store that is positively out of range blocks the order.
  Future<bool> _ensureStoreInDeliveryRange() async {
    try {
      final cartStoreId = _cartStoreId();
      if (cartStoreId == null) return true;

      final coords = await _currentCoordinates();
      if (coords == null) return true;
      if (!mounted) return true;

      await context.read<GetNearbyRestaurantsCubit>().pollNearbyRestaurants({
        "latitude": coords.lat,
        "longitude": coords.lng,
        "radius": _storeDeliveryRadiusKm,
        "page": 0,
        "size": 100,
      });
      if (!mounted) return true;

      final nearbyState = context.read<GetNearbyRestaurantsCubit>().state;
      if (nearbyState is! GetNearbyRestaurantsLoaded) return true;

      final storeInRange = nearbyState.model.content
          .any((store) => store.id?.toString() == cartStoreId);
      if (storeInRange) return true;

      await _showOutOfDeliveryRangeDialog();
      return false;
    } catch (e) {
      debugPrint('[Checkout] store-range check failed, allowing: $e');
      return true;
    }
  }

  /// The store id the current cart belongs to, from the loaded getCart state.
  /// Null when it can't be determined.
  String? _cartStoreId() {
    final state = context.read<GetCartCubit>().state;
    if (state is GetCartLoaded) {
      final id = state.cart.storeId?.trim();
      if (id != null && id.isNotEmpty && id != '0') return id;
    }
    return null;
  }

  /// Buyer's current coordinates — a last-known fix first (instant), then a
  /// tight live fix, then the saved coordinates. Null when nothing is
  /// available (checkout then fails open).
  Future<({double lat, double lng})?> _currentCoordinates() async {
    Position? position = await Geolocator.getLastKnownPosition();
    if (position == null) {
      final permission = await Geolocator.checkPermission();
      final granted = permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
      if (granted) {
        try {
          position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.low,
              timeLimit: Duration(seconds: 6),
            ),
          );
        } catch (_) {
          position = null;
        }
      }
    }
    if (position != null) {
      return (lat: position.latitude, lng: position.longitude);
    }

    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble('saved_latitude');
    final lng = prefs.getDouble('saved_longitude');
    if (lat != null && lng != null) return (lat: lat, lng: lng);
    return null;
  }

  /// Blocking popup shown when the cart's store no longer delivers to the
  /// buyer's current location. Replaces the old transient snackbar so the
  /// message can't be swiped away or missed, and makes clear the cart is kept.
  Future<void> _showOutOfDeliveryRangeDialog() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: AppColor.White,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.wrong_location_outlined,
                  size: 40,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "You're out of range",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                "You're far from the store, so this order can't be placed "
                "from here.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.PrimaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text("Got it"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Entry point for the bottom bar's "Place Order" button. Checks out with
  /// the payment method chosen in the dropdown:
  ///  - coupon applied → forced Cash on Delivery;
  ///  - nothing selected → prompt the buyer to pick one;
  ///  - COD → COD checkout API; online → Razorpay checkout.
  Future<void> _onPlaceOrderPressed() async {
    if (!await _ensureStoreInDeliveryRange()) return;
    if (!mounted) return;

    if (_isCouponApplied) {
      await openCodCheckout();
      return;
    }

    final method = _selectedPaymentMethod;
    if (method == null) {
      CustomSnackbars.showErrorSnack(
        context: context,
        title: "Attention",
        message: "Please select a payment method",
      );
      return;
    }

    if (method == _codPaymentCode) {
      await openCodCheckout(paymentMethod: _codPaymentCode);
    } else {
      await openCheckOut(paymentMethod: _onlinePaymentCode);
    }
  }

  /// Cash-on-delivery checkout — creates the order directly with no
  /// payment gateway step. Only offered while a coupon is applied.
  Future<void> openCodCheckout({String paymentMethod = "COD"}) async {
    if (_checkoutInFlight) return;
    _checkoutInFlight = true;
    try {
      if (selectedAddress == "Add Address") {
        CustomSnackbars.showErrorSnack(
          context: context,
          title: "Attention",
          message: "Select delivery address first",
        );
        return;
      }

      final activeCartId = await _ensureCartId();
      if (!mounted) return;
      if (!_hasValidCartId(activeCartId)) {
        CustomSnackbars.showErrorSnack(
          context: context,
          title: 'ERROR',
          message: 'Cart id not found',
        );
        return;
      }

      if (mounted) setState(() => loading = true);

      final payload = {
        "cartId": activeCartId,
        "shippingMethod": _shippingMethod,
        "shippingAddressId": _selectedAddressId ?? "",
        "paymentMethod": paymentMethod,
        "b2bUnitId": defaultB2bUnitId,
        if (_selectedPromoCode != null) "promoCode": _selectedPromoCode,
      };

      debugPrint('[Checkout] COD submit: cartId=$activeCartId');
      final result = await context.read<CheckoutCubit>().checkoutCod(payload);
      if (!mounted) return;
      setState(() => loading = false);

      if (result != null) {
        debugPrint(
          '[Checkout] COD success: orderId=${result.orderId}, '
          'orderStatus=${result.orderStatus}',
        );
        CartPrefs.clearOfferFlowAndApplied();
        CartPrefs.clearPaymentMethod();

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const OrderSuccessScreen()),
          (route) => false,
        );
      }
    } finally {
      _checkoutInFlight = false;
    }
  }

  void _stopCheckoutButtonLoading() {
    if (mounted) setState(() => loading = false);
  }

  Future<void> openCheckOut({String paymentMethod = "RAZORPAY"}) async {
    // Guard set synchronously (no await before it) so a fast double-tap
    // can't slip a second call in before `loading` flips the button off,
    // which was causing two checkout orders + two Razorpay opens.
    if (_checkoutInFlight) return;
    _checkoutInFlight = true;
    _processedRazorpayPaymentId = null;
    try {
      if (selectedAddress == "Add Address") {
        CustomSnackbars.showErrorSnack(
          context: context,
          title: "Attention",
          message: "Select delivery address first",
        );
        return;
      }

      // Button shows its loader from here until Razorpay's checkout sheet
      // actually opens (or we bail out below on an error).
      if (mounted) setState(() => loading = true);

      debugPrint('[Razorpay] Pay Online; creating checkout order');
      final checkout = await _submitCartCheckout(paymentMethod);
      if (checkout == null) {
        _stopCheckoutButtonLoading();
        return;
      }

      final razorpayOrderId = checkout.razorpayOrderId?.trim();
      if (!_hasValidCartId(razorpayOrderId)) {
        _stopCheckoutButtonLoading();
        CustomSnackbars.showErrorSnack(
          context: context,
          title: 'ERROR',
          message: 'Payment order id not received',
        );
        return;
      }
      final validRazorpayOrderId = razorpayOrderId!;

      final razorpayKeyId = RazorpayCheckoutHelper.firstNonEmpty(
        checkout.razorpayKeyId,
        razorPayKey,
      );
      if (razorpayKeyId == null) {
        _stopCheckoutButtonLoading();
        CustomSnackbars.showErrorSnack(
          context: context,
          title: 'ERROR',
          message: 'Razorpay key not received',
        );
        return;
      }

      final amountInPaise = RazorpayCheckoutHelper.amountInPaise(
        checkout,
        _grandTotal,
      );
      if (amountInPaise <= 0) {
        _stopCheckoutButtonLoading();
        CustomSnackbars.showErrorSnack(
          context: context,
          title: 'ERROR',
          message: 'Invalid payment amount',
        );
        return;
      }

      try {
        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          try {
            debugPrint(
              'Opening Razorpay checkout: orderId=$validRazorpayOrderId, '
              'amount=$amountInPaise, '
              'key=${RazorpayCheckoutHelper.maskKey(razorpayKeyId)}',
            );

            _razorpay.open(
              RazorpayCheckoutHelper.checkoutOptions(
                key: razorpayKeyId,
                amountInPaise: amountInPaise,
                razorpayOrderId: validRazorpayOrderId,
                prefill: _razorpayPrefill(),
                notes: RazorpayCheckoutHelper.notesFor(checkout, cartId),
              ),
            );
          } catch (e) {
            if (!mounted) return;
            CustomSnackbars.showErrorSnack(
              context: context,
              title: 'ERROR',
              message: friendlyErrorMessage(
                e,
                fallback:
                    'Unable to open the payment screen. Please try again.',
              ),
            );
          } finally {
            // Whether it opened or failed to, the button's job is done.
            _stopCheckoutButtonLoading();
          }
        });
      } catch (e) {
        _stopCheckoutButtonLoading();
        CustomSnackbars.showErrorSnack(
          context: context,
          title: 'ERROR',
          message: friendlyErrorMessage(
            e,
            fallback: 'Unable to open the payment screen. Please try again.',
          ),
        );
      }
    } finally {
      _checkoutInFlight = false;
    }
  }

  /// Pops the cart screen back to its opener, handing back the current
  /// quantities, and drops the transient offer-flow prefs on the way out.
  void _popWithCartResult({bool notifyBottomSheet = false}) {
    CartPrefs.clearOfferFlowAndApplied();

    final updatedCart = <dynamic, int>{};
    for (var item in selectedItems) {
      final productId = item['productId'] ?? item['id'];
      final qty = cart[item['name']] ?? 0;
      if (qty > 0) updatedCart[productId] = qty;
    }

    Navigator.pop(context, {
      'updatedCart': updatedCart,
      'cartItemsLength': getCartItemCount(),
    });

    if (notifyBottomSheet) {
      widget.onBottomSheetVisibilityChanged?.call(cart.isNotEmpty);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Delivery modes are read straight from the cubit so the dropdown renders
    // as soon as the API responds. The payment picker is a fixed two-choice
    // control that needs no API.
    final deliveryModesState = context.watch<DeliveryModesCubit>().state;
    final deliveryModes = _deliveryModesOf(deliveryModesState);

    // Selected code, but only if it's still one of the available options —
    // DropdownButtonFormField asserts the value exists in its items.
    final deliveryDropdownValue = deliveryModes
            .any((m) => m.checkoutCode == _selectedDeliveryMode)
        ? _selectedDeliveryMode
        : (deliveryModes.isNotEmpty ? deliveryModes.first.checkoutCode : null);

    return MultiBlocListener(
      listeners: [
        BlocListener<ProductsAddToCartCubit, ProductsAddToCartState>(
          listener: (context, state) {
            if (state is ProductsAddToCartFailure) {
              if ((state.message).isNotEmpty) {
                CustomSnackbars.showErrorSnack(
                  context: context,
                  title: "Failed",
                  message: state.message,
                );
              }
              setState(() => loading = false);
            } else if (state is ProductsAddToCartSuccess) {
              _maybeAutoValidateOffer();
              _refreshCheckout();
            }
          },
        ),
        BlocListener<GetCartCubit, GetCartState>(
          listener: (context, state) {
            if (state is GetCartLoaded) {
              setState(() {
                cartId = state.cart.id;
                notesController.text = state.cart.notes ?? "";
                selfOrder = false;
                _syncCartFromGetCart(state.cart);
              });
              _maybeAutoValidateOffer();

              // No auto-default. Restore the payment method the buyer saved
              // for this cart (prefs), else whatever the cart carries, else
              // leave it on "Select payment method".
              _syncPaymentMethodForCart(state.cart);

              _maybeFetchEligiblePromotions();
              _refreshCheckout();
              // Keep the checkout charge preview in step with the cart that
              // just loaded (self-guards when there's no payment method /
              // address yet).
              _refreshChargesPreview();

              final count = getCartItemCount();
              if (count != 1 && _isCouponApplied) {
                CartPrefs.removeOfferApplied();
                if (mounted) setState(() => _isCouponApplied = false);
              } else if (count == 1) {
                () async {
                  final sticky = await CartPrefs.isOfferApplied();
                  if (sticky && mounted) {
                    setState(() => _isCouponApplied = true);
                  }
                }();
              }
            }
          },
        ),
        BlocListener<GetAddressCubit, GetAddressState>(
          listener: (context, state) {
            if (state is GetAddressSuccess) {
              final addresses = state.addressModel.content;
              final hasAny = addresses.isNotEmpty;
              if (!hasAny) {
                _clearSavedAddress();
                return;
              }
              if (selectedAddress == "Add Address") {
                final defaultAddress = _formatAddress(addresses.first);
                final defaultAddressId = addresses.first.id;
                if (defaultAddress.isNotEmpty) {
                  _saveAddress(defaultAddress, addressId: defaultAddressId);
                  setState(() {
                    selectedAddress = defaultAddress;
                    _selectedAddressId = defaultAddressId;
                  });
                }
              }
              _refreshCheckout();
              // Now that an address is set, the checkout preview can run and
              // bring back the payment-method-aware breakdown.
              _refreshChargesPreview();
            }
          },
        ),
        BlocListener<UpdateCartItemsCubit, UpdateCartItemsState>(
          listener: (context, state) {
            if (state is UpdateCartItemsFailure) {
              CustomSnackbars.showErrorSnack(
                context: context,
                title: "Error",
                message: state.error.isEmpty
                    ? "Couldn't update the cart"
                    : state.error,
              );
            }
          },
        ),
        BlocListener<CheckoutCubit, CheckoutState>(
          listener: (context, state) {
            if (state is CheckoutSuccess) {
              // The checkout-preview response is the only one that reflects
              // the chosen payment method (COD fee / online discount /
              // delivery waiver), so its breakdown feeds the bottom bar via
              // `_preview*` — but only the fields it actually returned; a
              // missing field leaves the previous value (and the getCart
              // fallback) in place rather than blanking a correct total.
              final model = state.model;
              final breakdown = model.data;
              setState(() {
                final itemsTotal = breakdown?.itemsTotal?.toDouble();
                final taxTotal = breakdown?.taxTotal?.toDouble();
                final deliveryCharge = breakdown?.deliveryCharge?.toDouble();
                final grandTotal =
                    (model.totalAmount ?? breakdown?.grandTotal)?.toDouble();
                if (itemsTotal != null) _previewItemsTotal = itemsTotal;
                if (taxTotal != null) _previewTaxTotal = taxTotal;
                if (deliveryCharge != null) {
                  _previewDeliveryCharge = deliveryCharge;
                }
                if (grandTotal != null) _previewGrandTotal = grandTotal;
                _applyFlatCharges();
              });
            } else if (state is CheckoutFailure) {
              CustomSnackbars.showErrorSnack(
                context: context,
                title: "Error",
                message:
                    state.error.isEmpty
                        ? "Failed to load checkout details"
                        : state.error,
              );
            }
          },
        ),
        BlocListener<ApplyCouponCubit, ApplyCouponState>(
          listener: (context, state) {
            if (state is ApplyCouponFailure) {
              CustomSnackbars.showErrorSnack(
                context: context,
                title: "Promo code",
                message: state.error.isEmpty
                    ? "Couldn't update the promo code"
                    : state.error,
              );
              if (mounted) setState(() => _promoApplying = false);
            }
          },
        ),
        BlocListener<EligiblePromotionsCubit, EligiblePromotionsState>(
          listener: (context, state) {
            if (state is EligiblePromotionsLoaded) {
              setState(() {
                _eligiblePromotions = state.model.promotions;
                _promotionsLoading = false;
                _promotionsFetched = true;
                // Only drop the local selection if it's neither the coupon the
                // cart actually carries nor one of the eligible codes — an
                // applied coupon commonly stops appearing in the eligible list
                // and must keep showing until it's removed from the cart.
                if (_selectedPromoCode != null &&
                    _selectedPromoCode != _cartCouponCode &&
                    !_eligiblePromotions.any(
                      (p) => p.value == _selectedPromoCode,
                    )) {
                  _selectedPromoCode = null;
                }
              });
              _refreshCheckout();
            } else if (state is EligiblePromotionsFailure) {
              setState(() {
                _eligiblePromotions = [];
                _promotionsLoading = false;
                _promotionsFetched = true;
              });
              _refreshCheckout();
            }
          },
        ),
        // Once the delivery modes arrive, default the selection to the first
        // one so checkout always has a code to send. Rendering reads the
        // list directly from the cubit via context.watch in build().
        BlocListener<DeliveryModesCubit, DeliveryModesState>(
          listener: (context, state) {
            if (state is! DeliveryModesLoaded) return;
            final modes = state.model.activeModes;
            final stillValid =
                modes.any((m) => m.checkoutCode == _selectedDeliveryMode);
            if (!stillValid) {
              setState(() {
                _selectedDeliveryMode =
                    modes.isNotEmpty ? modes.first.checkoutCode : null;
              });
            }
          },
        ),
        BlocListener<ValidateOfferCubit, ValidateOfferState>(
          listener: (context, state) {
            if (state is ValidateOfferSuccess) {
              final res = state.validateOfferModel;

              final isSuccess = (res.status ?? '').toUpperCase() == 'SUCCESS';
              final saysTrue =
                  (res.data ?? '').toLowerCase() == 'true' ||
                  (res.message ?? '').toLowerCase() == 'true';

              if (isSuccess && saysTrue) {
                CustomSnackbars.showSuccessSnack(
                  context: context,
                  title: "Coupon Applied",
                  message: "Offer applied successfully!",
                );
                setState(() {
                  _isCouponApplied = true;
                });
                CartPrefs.setOfferApplied(true);
                _refreshCheckout();
              } else {
                CustomSnackbars.showErrorSnack(
                  context: context,
                  title: "Offer Expired",
                  message:
                      "Offer has expired. Please wait 10 minutes and try again.",
                );
                setState(() {
                  _isCouponApplied = false;
                });
                CartPrefs.clearOfferFlowAndApplied();
              }
            } else if (state is ValidateOfferFailure) {
              CustomSnackbars.showErrorSnack(
                context: context,
                title: "Error",
                message: state.error,
              );
              CartPrefs.clearOfferFlowAndApplied();
            }
          },
        ),
      ],
      child: WillPopScope(
        onWillPop: () async {
          _popWithCartResult();
          return false;
        },
        child: Scaffold(
          backgroundColor: AppColor.White,
          appBar: CustomAppBar(
            title: "Cart (${getCartItemCount()} items)",
            onBackPressed: () => _popWithCartResult(notifyBottomSheet: true),
          ),
          body: AbsorbPointer(
            // Only ever true while a payment operation (checkout/initiate,
            // COD, or verify-payment) is in flight, so this doesn't block
            // interaction outside that window.
            absorbing: loading,
            child: Column(
              children: [
                AddressCard(
                  address: selectedAddress,
                  onEdit: () async {
                    final result = await Navigator.push<Map<String, dynamic>>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddressScreen(selectionMode: true),
                      ),
                    );

                    final address = result?['address'] as String?;
                    final addressId = result?['addressId'] as String?;
                    if (address != null && address.isNotEmpty) {
                      await _saveAddress(address, addressId: addressId);
                      setState(() {
                        selectedAddress = address;
                        _selectedAddressId = addressId;
                      });
                      _refreshCheckout();
                      _refreshChargesPreview();
                    }
                  },
                ),
                // Payment method / delivery mode / promo-code selectors sit
                // above the item list, only while the cart has items.
                if (selectedItems.isNotEmpty)
                  CartOptionsSection(
                    selectedPaymentMethod: _selectedPaymentMethod,
                    paymentBusy: _paymentContextSyncing,
                    onPaymentMethodChanged: _onPaymentMethodChanged,
                    deliveryModes: deliveryModes,
                    deliveryModesLoading:
                        deliveryModesState is DeliveryModesLoading,
                    deliveryDropdownValue: deliveryDropdownValue,
                    onDeliveryModeChanged: (code) =>
                        setState(() => _selectedDeliveryMode = code),
                    promoCodes: _eligiblePromotions,
                    promotionsLoading: _promotionsLoading,
                    promoApplying: _promoApplying,
                    selectedPromoCode: _selectedPromoCode,
                    onPromoCodeChanged: _onPromoCodeChanged,
                  ),
                Expanded(
                  child:
                      selectedItems.isEmpty
                          ? EmptyCartView(
                            onAddItems: () {
                              widget.onBottomSheetVisibilityChanged?.call(false);
                              Navigator.of(context).pop();
                            },
                          )
                          : ListView.builder(
                            itemCount: selectedItems.length + 1,
                            itemBuilder: (ctx, i) {
                              if (i < selectedItems.length) {
                                final item = selectedItems[i];
                                final currentQuantity = cart[item['name']] ?? 1;
                                return CartItemCard(
                                  item: item,
                                  quantity: currentQuantity,
                                  enableIncrement:
                                      widget.orderId == null &&
                                      !_isCouponApplied,
                                  onQuantityChanged: (q) async {
                                    final name = item['name'];
                                    if (name == null) return;

                                    if (q == currentQuantity) return;

                                    if (q <= 0) {
                                      setState(() {
                                        cart.remove(name);
                                        selectedItems.removeAt(i);
                                      });
                                    } else {
                                      setState(() {
                                        cart[name] = q;
                                      });
                                    }

                                    final activeCartId = await _ensureCartId();
                                    if (!_hasValidCartId(activeCartId)) return;

                                    if (currentQuantity <= 0 && q > 0) {
                                      final payload = _singleItemCartPayload(
                                        item,
                                        1,
                                      );
                                      if (payload == null) return;
                                      await context
                                          .read<ProductsAddToCartCubit>()
                                          .addToCart(
                                            activeCartId,
                                            payload,
                                            context: context,
                                          );
                                    } else {
                                      await _updateExistingCartItemQuantity(
                                        activeCartId!,
                                        item,
                                        q,
                                      );
                                    }
                                    await context
                                        .read<GetCartCubit>()
                                        .fetchCart(context);
                                    _refreshCheckout();

                                    widget.onBottomSheetVisibilityChanged?.call(
                                      cart.isNotEmpty,
                                    );
                                  },
                                );
                              }

                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 20,
                                  horizontal: 16,
                                ),
                                child: CheckoutBottomBar(
                                  // Item total, delivery charge, tax,
                                  // platform fee, discount and the grand
                                  // total all come straight from the getCart
                                  // response — not the checkout-preview
                                  // endpoint (which can come back as 0
                                  // before a payment method/address is
                                  // chosen) and not gated behind
                                  // `_isCouponApplied`, whose sticky,
                                  // locally-persisted flag can outlive the
                                  // cart it was set for and used to force a
                                  // stale hardcoded total (e.g. showing 1
                                  // instead of the real grandTotal) even
                                  // when the cart has no coupon applied.
                                  itemTotal: _displayItemTotal,
                                  deliveryCharge: _displayDeliveryCharge,
                                  tax: _displayTax,
                                  discount: _cartTotalDiscount,
                                  platformFee: _cartPlatformFee,
                                  total: _displayGrandTotal,
                                  loading: loading,
                                  onPlaceOrder: _onPlaceOrderPressed,
                                ),
                              );
                            },
                          ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }
}
