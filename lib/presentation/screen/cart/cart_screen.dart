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
import 'package:local_basket/presentation/screen/widgets/cart/delivery_mode_dropdown.dart';
import 'package:local_basket/presentation/cubit/offers/restaurant_offers/validate_offers/validate_offer_cubit.dart';
import 'package:local_basket/presentation/cubit/offers/restaurant_offers/validate_offers/validate_offer_state.dart';
import 'package:local_basket/presentation/cubit/payment/checkout/checkout_cubit.dart';
import 'package:local_basket/presentation/cubit/payment/checkout/checkout_state.dart';
import 'package:local_basket/presentation/screen/widgets/cart/address_card.dart';
import 'package:local_basket/presentation/screen/widgets/cart/cart_item_card.dart';
import 'package:local_basket/presentation/screen/widgets/cart/checkout_bottom_bar.dart';
import 'package:local_basket/presentation/screen/widgets/cart/promo_code_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

  // Price breakdown from the checkout preview (`/api/carts/checkout`) — the
  // only source of the actually-applied charges. Null until a preview runs.
  double? _previewItemsTotal;
  double? _previewDelivery;
  double? _previewTax;
  double? _previewDiscount;
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

  bool get _hasEligiblePromotions => _eligiblePromotions.isNotEmpty;

  // Stores whose orders can only be paid by Cash on Delivery — the online
  // (Razorpay) option is hidden and only COD is offered when the cart belongs
  // to one of these stores.
  static const Set<String> _codOnlyStoreIds = {
    '425cda1f-07ce-428f-a122-581bc3751448',
  };

  /// storeId of the cart currently loaded from the getCart API.
  String? _cartStoreId;

  /// True when the loaded cart belongs to a store that only allows COD.
  bool get _isCodOnlyStore =>
      _cartStoreId != null && _codOnlyStoreIds.contains(_cartStoreId);

  // Payment method / delivery mode pickers. The payment picker is a fixed
  // two-choice control (COD / online); the delivery-mode list still comes
  // from its cubit. Only the current selection is kept as local state. The
  // selected payment method's `code` goes to checkout as `paymentMethod`,
  // the delivery mode's `code` as `shippingMethod`.
  static const String _codPaymentCode = PaymentMethodDropdown.codCode;
  static const String _onlinePaymentCode = PaymentMethodDropdown.onlineCode;

  // Starts null so the buyer always makes an explicit choice.
  String? _selectedPaymentMethod;
  String? _selectedDeliveryMode;

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
    setState(() {
      _selectedPaymentMethod = code;
      // The previously picked promo may no longer apply to the new method.
      _selectedPromoCode = null;
    });
    _maybeFetchEligiblePromotions(force: true, background: true);
    await _persistCartContext();
    if (!mounted) return;
    _maybeFetchEligiblePromotions(force: true, background: true);
    _refreshChargesPreview();
  }

  /// Called when the buyer picks (or clears) a promo code — persists it onto
  /// the cart, refreshes the checkout charge preview and flashes a brief
  /// confirmation toast that auto-dismisses after 2 seconds.
  void _onPromoCodeChanged(String? code) {
    if (code == _selectedPromoCode) return;
    setState(() => _selectedPromoCode = code);
    _persistCartContext();
    _refreshChargesPreview();
    if (code != null && code.isNotEmpty) {
      CustomSnackbars.showSuccessSnack(
        context: context,
        title: "Promo code applied",
        message: "Successfully added promo code \"$code\" to your cart",
        duration: const Duration(seconds: 2),
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
    if (!mounted || !_hasValidCartId(activeCartId)) return;

    final item = selectedItems.first;
    final cartItemId = await _cartItemIdForProduct(item);
    if (!mounted || !_hasValidCartId(cartItemId)) {
      debugPrint('[CartContext] no cart item id; skipping persist');
      return;
    }

    final quantity =
        cart[item['name']] ?? ((item['quantity'] as num?)?.toInt() ?? 1);
    final payload = <String, dynamic>{
      "quantity": quantity,
      "paymentMethod": _selectedPaymentMethod,
      "shippingMethod": _shippingMethod,
      if (_selectedPromoCode != null) "couponCode": _selectedPromoCode,
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
      final prefs = await SharedPreferences.getInstance();
      final applied = prefs.getBool('offer_applied') ?? false;
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
      () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('is_offer_flow');
        await prefs.remove('offer_id');
        await prefs.remove('offer_coupon');
        await prefs.remove('offer_started_at');
        await prefs.remove('offer_applied');
      }();

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
    debugPrint('[Razorpay] failure: ${_formatRazorpayFailure(response)}');
    CustomSnackbars.showErrorSnack(
      context: context,
      title: 'Failed',
      message: _formatRazorpayFailure(response),
    );

    final error = response is PaymentFailureResponse ? response.error : null;
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
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedAddress = prefs.getString('delivery_address') ?? "Add Address";
      _selectedAddressId = prefs.getString('delivery_address_id');
    });
  }

  Future<void> _clearSavedAddress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('delivery_address');
    await prefs.remove('delivery_address_id');
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

      final prefs = await SharedPreferences.getInstance();
      final isOfferFlow = prefs.getBool('is_offer_flow') ?? false;
      final stickyApplied = prefs.getBool('offer_applied') ?? false;
      final offerId = (prefs.getString('offer_id') ?? '').trim();

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

  Future<void> _saveAddress(String address, {String? addressId}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('delivery_address', address);
    if (addressId != null && addressId.isNotEmpty) {
      await prefs.setString('delivery_address_id', addressId);
    } else {
      await prefs.remove('delivery_address_id');
    }
  }

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
  }

  void _syncCartFromGetCart(GetCartModel loadedCart) {
    cart.clear();
    selectedItems.clear();

    _cartStoreId = loadedCart.storeId;

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

    _subtotal = (loadedCart.subTotal ?? 0).toDouble();
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

  String? _firstNonEmpty(String? primary, String fallback) {
    final primaryValue = primary?.trim();
    if (primaryValue != null && primaryValue.isNotEmpty) return primaryValue;

    final fallbackValue = fallback.trim();
    return fallbackValue.isEmpty ? null : fallbackValue;
  }

  String? _trimmedValue(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  String? _formattedContact(String? value) {
    final trimmed = _trimmedValue(value);
    if (trimmed == null) return null;
    if (trimmed.startsWith('+')) return trimmed;

    final digitsOnly = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length == 10) return '+91$digitsOnly';
    if (digitsOnly.length == 12 && digitsOnly.startsWith('91')) {
      return '+$digitsOnly';
    }
    return digitsOnly.isEmpty ? trimmed : digitsOnly;
  }

  Map<String, dynamic> _razorpayPrefill() {
    final prefill = <String, dynamic>{};

    try {
      final state = context.read<CurrentCustomerCubit>().state;
      if (state is CurrentCustomerLoaded) {
        final customer = state.currentCustomerModel;
        final name =
            _trimmedValue(
              [customer.firstName, customer.lastName]
                  .whereType<String>()
                  .map((part) => part.trim())
                  .where((part) => part.isNotEmpty)
                  .join(' '),
            ) ??
            _trimmedValue(customer.username);
        final email = _trimmedValue(customer.email);
        final contact = _formattedContact(customer.mobile);

        if (name != null) prefill['name'] = name;
        if (email != null) prefill['email'] = email;
        if (contact != null) prefill['contact'] = contact;
      }
    } catch (_) {}

    return prefill;
  }

  Map<String, dynamic> _razorpayNotes(CheckoutModel checkout) {
    final notes = <String, dynamic>{};

    void addNote(String key, Object? value) {
      final text = value?.toString().trim();
      if (text != null && text.isNotEmpty) notes[key] = text;
    }

    addNote('appOrderId', checkout.orderId);
    addNote('razorpayOrderId', checkout.razorpayOrderId);
    addNote('orderStatus', checkout.orderStatus);
    addNote('paymentStatus', checkout.paymentStatus);
    addNote('fraudFlagged', checkout.fraudFlagged);
    addNote('cartId', cartId);
    if (checkout.crossSellProductIds.isNotEmpty) {
      addNote('crossSellProductIds', checkout.crossSellProductIds.join(','));
    }

    return notes;
  }

  Map<String, dynamic> _razorpayUpiFirstConfig() {
    return {
      'display': {
        'blocks': {
          'upi_apps': {
            'name': 'Pay via UPI',
            'instruments': [
              {'method': 'upi'},
            ],
          },
          'other_methods': {
            'name': 'Cards, Wallets & Netbanking',
            'instruments': [
              {'method': 'card'},
              {'method': 'wallet'},
              {'method': 'netbanking'},
            ],
          },
        },
        'sequence': ['block.upi_apps', 'block.other_methods'],
        'preferences': {'show_default_blocks': true},
      },
    };
  }

  Map<String, dynamic> _razorpayCheckoutOptions({
    required String key,
    required int amountInPaise,
    required String razorpayOrderId,
    required CheckoutModel checkout,
  }) {
    return {
      'key': key,
      'amount': amountInPaise,
      'currency': 'INR',
      'name': 'Local Basket',
      'order_id': razorpayOrderId,
      'method': 'upi',
      'description': 'Cart Payment',
      'prefill': _razorpayPrefill(),
      'notes': _razorpayNotes(checkout),
      'config': _razorpayUpiFirstConfig(),
      'retry': {'enabled': true, 'max_count': 1},
      'timeout': 60,
      'theme': {'color': '#081724'},
    };
  }

  int _checkoutAmountInPaise(CheckoutModel checkout) {
    final amount =
        checkout.totalAmount ?? checkout.data?.grandTotal ?? _grandTotal;
    return (amount * 100).round();
  }

  String _maskedRazorpayKey(String key) {
    final trimmed = key.trim();
    if (trimmed.length <= 8) return '****';
    return '${trimmed.substring(0, 8)}...${trimmed.substring(trimmed.length - 4)}';
  }

  String _formatRazorpayFailure(dynamic response) {
    if (response is PaymentFailureResponse) {
      final details = <String>[];
      final message = response.message?.trim();
      final code = response.code;
      final error = response.error;
      final reason = error?['reason']?.toString().trim();
      final description = error?['description']?.toString().trim();

      if (message != null && message.isNotEmpty) details.add(message);
      if (code != null) details.add('Code: $code');
      if (reason != null && reason.isNotEmpty && reason != message) {
        details.add('Reason: $reason');
      }
      if (description != null &&
          description.isNotEmpty &&
          description != message) {
        details.add(description);
      }

      return details.isEmpty ? 'Payment failed' : details.join('\n');
    }

    final message = response?.toString().trim();
    return message == null || message.isEmpty ? 'Payment failed' : message;
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

  /// The buyer's current picks (payment method, shipping method and the promo
  /// code chosen from the eligible-promotions list) that ride along with the
  /// add-items-to-cart request. Each key is only included once a value is
  /// available, so nothing changes until the user actually makes a choice.
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

    final couponCode = _selectedPromoCode?.trim();
    if (couponCode != null && couponCode.isNotEmpty) {
      fields["couponCode"] = couponCode;
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
        'key=${initiated.razorpayKeyId == null ? null : _maskedRazorpayKey(initiated.razorpayKeyId!)}',
      );
    } else {
      debugPrint('[Checkout] initiate failed: response is null');
    }

    return initiated;
  }

  /// Entry point for the bottom bar's "Place Order" button. Checks out with
  /// the payment method chosen in the dropdown:
  ///  - coupon applied / COD-only store → forced Cash on Delivery;
  ///  - nothing selected → prompt the buyer to pick one;
  ///  - COD → COD checkout API; online → Razorpay checkout.
  Future<void> _onPlaceOrderPressed() async {
    if (_isCouponApplied || _isCodOnlyStore) {
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
        () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('is_offer_flow');
          await prefs.remove('offer_id');
          await prefs.remove('offer_coupon');
          await prefs.remove('offer_started_at');
          await prefs.remove('offer_applied');
        }();

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

      final razorpayKeyId = _firstNonEmpty(checkout.razorpayKeyId, razorPayKey);
      if (razorpayKeyId == null) {
        _stopCheckoutButtonLoading();
        CustomSnackbars.showErrorSnack(
          context: context,
          title: 'ERROR',
          message: 'Razorpay key not received',
        );
        return;
      }

      final amountInPaise = _checkoutAmountInPaise(checkout);
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
        await Future<void>.delayed(const Duration(milliseconds: 200));
        WidgetsBinding.instance.addPostFrameCallback((_) {
          try {
            debugPrint(
              'Opening Razorpay checkout: orderId=$validRazorpayOrderId, '
              'amount=$amountInPaise, key=${_maskedRazorpayKey(razorpayKeyId)}',
            );

            _razorpay.open(
              _razorpayCheckoutOptions(
                key: razorpayKeyId,
                amountInPaise: amountInPaise,
                razorpayOrderId: validRazorpayOrderId,
                checkout: checkout,
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
              _maybeFetchEligiblePromotions();
              _refreshCheckout();

              final count = getCartItemCount();
              if (count != 1 && _isCouponApplied) {
                () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('offer_applied');
                }();
                if (mounted) setState(() => _isCouponApplied = false);
              } else if (count == 1) {
                () async {
                  final prefs = await SharedPreferences.getInstance();
                  final sticky = prefs.getBool('offer_applied') ?? false;
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
              final data = state.model.data;
              setState(() {
                _subtotal = (data?.itemsTotal ?? 0).toDouble();
                _previewItemsTotal = data?.itemsTotal?.toDouble();
                _previewDelivery = data?.deliveryCharge?.toDouble();
                _previewTax = data?.taxTotal?.toDouble();
                _previewGrandTotal =
                    data?.grandTotal?.toDouble() ??
                    state.model.totalAmount?.toDouble();
                final items = _previewItemsTotal;
                final grand = _previewGrandTotal;
                if (items != null && grand != null) {
                  final charges =
                      (_previewDelivery ?? 0) + (_previewTax ?? 0);
                  final discount = items + charges - grand;
                  _previewDiscount = discount > 0 ? discount : 0;
                } else {
                  _previewDiscount = null;
                }
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
        BlocListener<EligiblePromotionsCubit, EligiblePromotionsState>(
          listener: (context, state) {
            if (state is EligiblePromotionsLoaded) {
              setState(() {
                _eligiblePromotions = state.model.promotions;
                _promotionsLoading = false;
                _promotionsFetched = true;
                if (_selectedPromoCode != null &&
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
                () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('offer_applied', true);
                }();
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
                () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('offer_applied');
                  await prefs.remove('is_offer_flow');
                  await prefs.remove('offer_id');
                  await prefs.remove('offer_coupon');
                  await prefs.remove('offer_started_at');
                }();
              }
            } else if (state is ValidateOfferFailure) {
              CustomSnackbars.showErrorSnack(
                context: context,
                title: "Error",
                message: state.error,
              );
              () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('offer_applied');
                await prefs.remove('is_offer_flow');
                await prefs.remove('offer_id');
                await prefs.remove('offer_coupon');
                await prefs.remove('offer_started_at');
              }();
            }
          },
        ),
      ],
      child: WillPopScope(
        onWillPop: () async {
          () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('is_offer_flow');
            await prefs.remove('offer_id');
            await prefs.remove('offer_coupon');
            await prefs.remove('offer_started_at');
          }();

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
          return false;
        },
        child: Scaffold(
          backgroundColor: AppColor.White,
          appBar: CustomAppBar(
            title: "Cart (${getCartItemCount()} items)",
            onBackPressed: () {
              () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('is_offer_flow');
                await prefs.remove('offer_id');
                await prefs.remove('offer_coupon');
                await prefs.remove('offer_started_at');
              }();
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

              widget.onBottomSheetVisibilityChanged?.call(cart.isNotEmpty);
            },
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
                // Payment method + delivery mode selectors sit above the
                // promo-code dropdown. The "Add notes" field was removed.
                // The payment dropdown is always shown while the cart has
                // items (even in the coupon / COD-only flows, where checkout
                // still forces COD regardless of the pick).
                if (selectedItems.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                    child: PaymentMethodDropdown(
                      selectedCode: _selectedPaymentMethod,
                      onChanged: _onPaymentMethodChanged,
                    ),
                  ),
                // Delivery-mode dropdown is only shown when the API returns
                // more than one active mode; a single mode is applied silently.
                if (selectedItems.isNotEmpty && deliveryModes.length > 1)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: DeliveryModeDropdown(
                      modes: deliveryModes,
                      loading: deliveryModesState is DeliveryModesLoading,
                      selectedCode: deliveryDropdownValue,
                      onChanged: (code) =>
                          setState(() => _selectedDeliveryMode = code),
                    ),
                  ),
                if (selectedItems.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: PromoCodeDropdown(
                      promoCodes: _eligiblePromotions,
                      loading: _promotionsLoading,
                      selectedPromoCode: _selectedPromoCode,
                      enabled: _selectedPaymentMethod != null,
                      onChanged: _onPromoCodeChanged,
                    ),
                  ),
                Expanded(
                  child:
                      selectedItems.isEmpty
                          ? Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24.0,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    "Your cart is empty",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ElevatedButton(
                                    onPressed: () {
                                      widget.onBottomSheetVisibilityChanged
                                          ?.call(false);
                                      Navigator.of(context).pop();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColor.PrimaryColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 12,
                                      ),
                                    ),
                                    child: const Text(
                                      "Add items",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
                                  itemTotal: _isCouponApplied
                                      ? 0
                                      : (_previewItemsTotal ?? _subtotal),
                                  deliveryCharge: _isCouponApplied
                                      ? 0
                                      : (_previewDelivery ?? _deliveryCharge),
                                  tax: _isCouponApplied
                                      ? 0
                                      : (_previewTax ?? 0),
                                  discount: _isCouponApplied
                                      ? 0
                                      : (_previewDiscount ?? 0),
                                  total: _isCouponApplied
                                      ? 1.0
                                      : (_previewGrandTotal ?? _grandTotal),
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
