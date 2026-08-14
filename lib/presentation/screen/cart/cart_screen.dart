import 'package:flutter/cupertino.dart';
import 'package:local_basket/presentation/cubit/authentication/currentcustomer/get/current_customer_cubit.dart';
import 'package:local_basket/presentation/cubit/authentication/currentcustomer/get/current_customer_state.dart';
import 'package:local_basket/data/model/cart/getCart/getCart_model.dart';
import 'package:local_basket/data/model/payment/checkout_model.dart';
import 'package:local_basket/presentation/cubit/offers/restaurant_offers/validate_offers/validate_offer_cubit.dart';
import 'package:local_basket/presentation/cubit/offers/restaurant_offers/validate_offers/validate_offer_state.dart';
import 'package:local_basket/presentation/cubit/payment/checkout/checkout_cubit.dart';
import 'package:local_basket/presentation/cubit/payment/checkout/checkout_state.dart';
import 'package:local_basket/presentation/screen/widgets/cart/address_card.dart';
import 'package:local_basket/presentation/screen/widgets/cart/cart_item_card.dart';
import 'package:local_basket/presentation/screen/widgets/cart/checkout_bottom_bar.dart';
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
import 'package:local_basket/presentation/cubit/payment/payment/payment_cubit.dart';
import 'package:local_basket/presentation/cubit/payment/payment/payment_state.dart';
import 'package:local_basket/presentation/screen/address/address_screen.dart';
import 'package:local_basket/presentation/screen/dashboard/dashboard_screen.dart';
import 'package:local_basket/presentation/screen/order/orderSuccess_screen.dart';
// FIX: Import Razorpay keys from api_constants instead of hardcoding them here.
import 'package:local_basket/core/constants/api_constants.dart';

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
  String? _pendingCheckoutOrderId;
  bool loading = false;
  String selectedAddress = "Add Address";
  bool selfOrder = false;

  double _subtotal = 0.0;
  double _gstAmount = 0.0;
  double _deliveryCharge = 0.0;
  double _grandTotal = 0.0;
  bool _checkoutLoading = false;

  @override
  void initState() {
    super.initState();
    _razorpay =
        Razorpay()
          ..on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess)
          ..on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentFailure)
          ..on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);

    context.read<GetCartCubit>().fetchCart(context);
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
        _gstAmount = 0;
        _deliveryCharge = 0;
        _grandTotal = 0;
      });
    }
  }

  void _onPaymentSuccess(PaymentSuccessResponse response) async {
    debugPrint(
      '[Razorpay] success: paymentId=${response.paymentId}, '
      'orderId=${response.orderId}, signaturePresent=${response.signature != null}',
    );

    final payload = {
      "orderId": _pendingCheckoutOrderId,
      "cartId": cartId ?? "",
      "amount": _grandTotal,
      "paymentId": response.paymentId,
      "razorpayOrderId": response.orderId,
      "razorpaySignature": response.signature,
      "status": "SUCCESS",
    };
    print('Payment success payload: $payload');
    setState(() => loading = true);
    await context.read<PaymentCubit>().makePayment(
      context: context,
      paymentType: 'ONLINE',
      paymentPayload: payload,
    );
    setState(() => loading = false);
  }

  void _onPaymentFailure(dynamic response) {
    if (!mounted) return;
    debugPrint('[Razorpay] failure: ${_formatRazorpayFailure(response)}');
    CustomSnackbars.showErrorSnack(
      context: context,
      title: 'Failed',
      message: _formatRazorpayFailure(response),
    );
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
    setState(
      () =>
          selectedAddress =
              prefs.getString('delivery_address') ?? "Add Address",
    );
  }

  Future<void> _clearSavedAddress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('delivery_address');
    if (!mounted) return;
    setState(() => selectedAddress = "Add Address");
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

  Future<void> _saveAddress(String address) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('delivery_address', address);
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
    _gstAmount = (loadedCart.totalTax ?? 0).toDouble();
    _grandTotal = (loadedCart.grandTotal ?? 0).toDouble();
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
    return {"productId": productId, "quantity": quantity};
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
      "shippingMethod": "STANDARD",
      "paymentMethod": paymentMethod,
      "shippingAddressId":"",
    };

    debugPrint(
      '[Checkout] submit: paymentMethod=$paymentMethod, cartId=$activeCartId',
    );
    setState(() => loading = true);
    final checkout = await context.read<CheckoutCubit>().fetchCheckout(payload);
    if (mounted) setState(() => loading = false);

    if (checkout != null) {
      _pendingCheckoutOrderId = checkout.orderId;
      debugPrint(
        '[Checkout] success: orderId=${checkout.orderId}, '
        'razorpayOrderId=${checkout.razorpayOrderId}, '
        'totalAmount=${checkout.totalAmount}, '
        'grandTotal=${checkout.data?.grandTotal}, '
        'key=${checkout.razorpayKeyId == null ? null : _maskedRazorpayKey(checkout.razorpayKeyId!)}',
      );
    } else {
      debugPrint('[Checkout] failed: checkout response is null');
    }

    return checkout;
  }

  Future<void> _completeCheckoutOrder(CheckoutModel checkout) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('offer_applied');
    await prefs.remove('is_offer_flow');
    await prefs.remove('offer_id');
    await prefs.remove('offer_coupon');
    await prefs.remove('offer_started_at');

    if (!mounted) return;

    CustomSnackbars.showSuccessSnack(
      context: context,
      title: 'Success',
      message: 'Order placed successfully',
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const OrderSuccessScreen()),
    );
  }

  Future<void> openCheckOut() async {
    if (selectedAddress == "Add Address") {
      CustomSnackbars.showErrorSnack(
        context: context,
        title: "Attention",
        message: "Select delivery address first",
      );
      return;
    }

    final paymentMethod = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: AppColor.White,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.payment_rounded,
                  color: Colors.orange,
                  size: 60,
                ),
                const SizedBox(height: 12),
                const Text(
                  "Select Payment Method",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: Colors.green,
                  ),
                  title: const Text("Pay Online"),
                  onTap: () => Navigator.pop(context, "RAZORPAY"),
                ),
                ListTile(
                  leading: const Icon(Icons.money, color: Colors.brown),
                  title: const Text("Cash on Delivery (COD)"),
                  onTap: () => Navigator.pop(context, "COD"),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (paymentMethod == null) return;

    if (paymentMethod == "COD") {
      final confirmCOD = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return Dialog(
            backgroundColor: AppColor.White,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 60,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Confirm COD Order",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "You've selected Cash on Delivery.\nPlease pay at the time of delivery.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.black54,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("Cancel"),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.PrimaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text("Confirm COD"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );

      if (confirmCOD == true) {
        final checkout = await _submitCartCheckout("COD");
        if (checkout != null) {
          await _completeCheckoutOrder(checkout);
        }
      }
      return;
    }

    debugPrint('[Razorpay] Pay Online selected; creating checkout order');
    final checkout = await _submitCartCheckout("RAZORPAY");
    if (checkout == null) return;

    final razorpayOrderId = checkout.razorpayOrderId?.trim();
    if (!_hasValidCartId(razorpayOrderId)) {
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
      CustomSnackbars.showErrorSnack(
        context: context,
        title: 'ERROR',
        message: 'Razorpay key not received',
      );
      return;
    }

    final amountInPaise = _checkoutAmountInPaise(checkout);
    if (amountInPaise <= 0) {
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
            message: e.toString(),
          );
        }
      });
    } catch (e) {
      CustomSnackbars.showErrorSnack(
        context: context,
        title: 'ERROR',
        message: e.toString(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ProductsAddToCartCubit, ProductsAddToCartState>(
          listener: (context, state) {
            if (state is ProductsAddToCartFailure) {
              if ((state.message).isNotEmpty) {
                CustomSnackbars.showErrorSnack(
                  context: context,
                  title: "Failed",
                  message: "Something went wrong",
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
              _refreshCheckout();
            }
          },
        ),
        BlocListener<CheckoutCubit, CheckoutState>(
          listener: (context, state) {
            if (state is CheckoutLoading) {
              setState(() => _checkoutLoading = true);
            } else if (state is CheckoutSuccess) {
              final data = state.model.data;
              setState(() {
                _subtotal = (data?.itemsTotal ?? 0).toDouble();
                _gstAmount = (data?.taxTotal ?? 0).toDouble();
                _deliveryCharge = (data?.deliveryCharge ?? 0).toDouble();
                _grandTotal = (data?.grandTotal ?? 0).toDouble();
                _checkoutLoading = false;
              });
            } else if (state is CheckoutFailure) {
              setState(() => _checkoutLoading = false);
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
        BlocListener<PaymentCubit, PaymentState>(
          listener: (context, state) {
            if (state is PaymentRefundSuccess) {
              CustomSnackbars.showErrorSnack(
                context: context,
                title: 'Failed',
                message: 'Payment failed. Refund will be initiated if debited.',
              );
            } else if (state is PaymentSuccess) {
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
            } else if (state is PaymentFailure) {
              CustomSnackbars.showErrorSnack(
                context: context,
                title: 'Failed',
                message: state.error.isEmpty ? "Payment Failed" : state.error,
              );
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
          body: Column(
            children: [
              AddressCard(
                address: selectedAddress,
                onEdit: () async {
                  final address = await Navigator.push<String>(
                    context,
                    MaterialPageRoute(builder: (_) => const AddressScreen()),
                  );

                  if (address != null) {
                    await _saveAddress(address);
                    setState(() => selectedAddress = address);
                    _refreshCheckout();
                  }
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: InkWell(
                  onTap: () async {
                    final newNote = await showDialog<String>(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: const Text("📝 Add Notes"),
                            content: TextField(
                              controller: notesController,
                              decoration: const InputDecoration(
                                hintText: "e.g. Deliver between 5–6 PM",
                              ),
                              maxLines: 3,
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("Cancel"),
                              ),
                              TextButton(
                                onPressed:
                                    () => Navigator.pop(
                                      context,
                                      notesController.text.trim(),
                                    ),
                                child: const Text("OK"),
                              ),
                            ],
                          ),
                    );
                    if (newNote != null) {
                      setState(() => notesController.text = newNote);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.notes_rounded, color: Colors.orange),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            notesController.text.isEmpty
                                ? "Add notes"
                                : notesController.text,
                            style: TextStyle(
                              color:
                                  notesController.text.isEmpty
                                      ? Colors.grey
                                      : Colors.black,
                              fontStyle:
                                  notesController.text.isEmpty
                                      ? FontStyle.italic
                                      : FontStyle.normal,
                            ),
                          ),
                        ),
                        const Icon(Icons.edit, size: 18, color: Colors.grey),
                      ],
                    ),
                  ),
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
                                    widget.onBottomSheetVisibilityChanged?.call(
                                      false,
                                    );
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
                                    widget.orderId == null && !_isCouponApplied,
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
                                  await context.read<GetCartCubit>().fetchCart(
                                    context,
                                  );
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
                              child:
                                  _checkoutLoading
                                      ? const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(20.0),
                                          child: CupertinoActivityIndicator(),
                                        ),
                                      )
                                      : CheckoutBottomBar(
                                        subtotal:
                                            _isCouponApplied ? 0 : _subtotal,
                                        gst: _isCouponApplied ? 0 : _gstAmount,
                                        deliveryCharge:
                                            _isCouponApplied
                                                ? 0
                                                : _deliveryCharge,
                                        total:
                                            _isCouponApplied
                                                ? 1.0
                                                : _grandTotal,
                                        loading: loading,
                                        onPlaceOrder: openCheckOut,
                                      ),
                            );
                          },
                        ),
              ),
            ],
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
