import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:local_basket/presentation/cubit/cart/clearCart/clearCart_cubit.dart';
import 'package:local_basket/presentation/cubit/offers/restaurant_offers/validate_offers/validate_offer_cubit.dart';
import 'package:local_basket/presentation/cubit/offers/restaurant_offers/validate_offers/validate_offer_state.dart';
import 'package:local_basket/presentation/cubit/payment/checkout/checkout_cubit.dart';
import 'package:local_basket/presentation/cubit/payment/checkout/checkout_state.dart';
import 'package:local_basket/presentation/screen/widgets/cart/address_card.dart';
import 'package:local_basket/presentation/screen/widgets/cart/cart_item_card.dart';
import 'package:local_basket/presentation/screen/widgets/cart/checkout_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_basket/core/constants/colors.dart';
import 'package:local_basket/components/custom_snackbar.dart';
import 'package:local_basket/components/custom_topbar.dart';
import 'package:local_basket/presentation/cubit/cart/getCart/getCart_cubit.dart';
import 'package:local_basket/presentation/cubit/cart/getCart/getCart_state.dart';
import 'package:local_basket/presentation/cubit/cart/productsAddToCart/productsAddtoCart_cubit.dart';
import 'package:local_basket/presentation/cubit/cart/productsAddToCart/productsAddtoCart_state.dart';
import 'package:local_basket/presentation/cubit/payment/payment/payment_cubit.dart';
import 'package:local_basket/presentation/cubit/payment/payment/payment_state.dart';
import 'package:local_basket/presentation/screen/address/address_screen.dart';
import 'package:local_basket/presentation/screen/dashboard/dashboard_screen.dart';

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
  static const razorPayKey = 'rzp_test_aa2AmRQV2HpRyT';
  static const razorPaySecret = 'UMfObdnXjWv3opzzTwHwAiv8';
  final TextEditingController notesController = TextEditingController();

  final TextEditingController couponController = TextEditingController();
  bool _isCouponApplied = false;

  bool _offerValidationInFlight = false;
  DateTime? _lastOfferValidationAt;

  final Map<String, int> cart = {};
  final List<Map<String, dynamic>> selectedItems = [];
  int? cartId;
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
    _razorpay = Razorpay()
      ..on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess)
      ..on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentFailure)
      ..on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);

    context.read<GetCartCubit>().fetchCart(context);
    _loadSavedAddress();
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
    if (selectedItems.isNotEmpty) {
      context.read<CheckoutCubit>().fetchCheckout();
    }
  }

  void _onPaymentSuccess(PaymentSuccessResponse response) async {
    final payload = {
      "cartId": cartId ?? 0,
      "amount": _grandTotal,
      "paymentId": response.paymentId,
      "razorpayOrderId": response.orderId,
      "razorpaySignature": response.signature,
      "status": "SUCCESS"
    };
    setState(() => loading = true);
    await context.read<PaymentCubit>().makePayment(
          context: context,
          paymentType: 'ONLINE',
          paymentPayload: payload,
        );
    setState(() => loading = false);
  }

  void _onPaymentFailure(_) {
    CustomSnackbars.showErrorSnack(
        context: context, title: 'Failed', message: 'Payment failed');
    setState(() => loading = false);
  }

  void _onExternalWallet(_) {
    CustomSnackbars.showInfoSnack(
        context: context, title: 'Info', message: 'Check payment status later');
    setState(() => loading = false);
  }

  Future<void> _loadSavedAddress() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() =>
        selectedAddress = prefs.getString('delivery_address') ?? "Add Address");
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

      final hasExactlyOne = getCartItemCount() == 1;
      if (hasExactlyOne) {
        if (stickyApplied) {
          if (mounted) setState(() => _isCouponApplied = true);
          return;
        }
        if (!isOfferFlow) return;
        _offerValidationInFlight = true;
        _lastOfferValidationAt = now;
        try {
          await context.read<ValidateOfferCubit>().validateOffer();
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

  int getCartItemCount() => cart.values.fold(0, (sum, q) => sum + q);

  Future<Map<String, dynamic>> _createOrder(int amount) async {
    final auth =
        'Basic ${base64Encode(utf8.encode('$razorPayKey:$razorPaySecret'))}';
    final headers = {'content-type': 'application/json', 'Authorization': auth};
    final data = {"amount": amount, "currency": "INR", "receipt": "rcptid_11"};
    final request =
        http.Request('POST', Uri.parse('https://api.razorpay.com/v1/orders'))
          ..body = json.encode(data)
          ..headers.addAll(headers);
    final response = await request.send();
    final body = jsonDecode(await response.stream.bytesToString());
    return {
      "status": response.statusCode == 200 ? "success" : "fail",
      "body": body
    };
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.payment_rounded,
                    color: Colors.orange, size: 60),
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
                // ListTile(
                //   leading: const Icon(Icons.account_balance_wallet_outlined,
                //       color: Colors.green),
                //   title: const Text("Pay Online (Razorpay)"),
                //   onTap: () => Navigator.pop(context, "ONLINE"),
                // ),
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
                  const Icon(Icons.warning_amber_rounded,
                      color: Colors.orange, size: 60),
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
        final payload = {
          "cartId": cartId ?? 0,
          "amount": _grandTotal,
          "paymentId": null,
          "razorpayOrderId": null,
          "razorpaySignature": null,
          "status": "COD"
        };

        setState(() => loading = true);
        await context.read<PaymentCubit>().makePayment(
              context: context,
              paymentType: 'CASH',
              paymentPayload: payload,
            );
        setState(() => loading = false);
      }
      return;
    }

    final proceed = await showDialog<bool>(
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
                Icon(Icons.warning_amber_rounded,
                    color: Colors.orange, size: 60),
                const SizedBox(height: 16),
                const Text(
                  "Before You Proceed",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "⚠️ Payments once made cannot be cancelled or refunded.\n\n"
                  "Please review your order before proceeding.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
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
                      child: const Text(
                        "I Understand, Proceed",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (proceed != true) return;

    final amountInPaise = (_grandTotal * 100).toInt();
    final orderResp = await _createOrder(amountInPaise);
    if (orderResp["status"] != "success") {
      CustomSnackbars.showErrorSnack(
        context: context,
        title: 'ERROR',
        message: 'Payment gateway error',
      );
      return;
    }

    _razorpay.open({
      'key': razorPayKey,
      'amount': amountInPaise,
      'name': 'Local Basket',
      'order_id': orderResp['body']['id'],
      'description': 'Cart Payment',
      'prefill': {'contact': '9705047662', 'email': 'harishpeela03@gmail.com'},
      'theme': {'color': '#081724'}
    });
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
                    message: "Something went wrong");
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
                selfOrder = state.cart.selfOrder ?? false;
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
                  if (sticky && mounted)
                    setState(() => _isCouponApplied = true);
                }();
              }
            }
          },
        ),
        BlocListener<CheckoutCubit, CheckoutState>(
          listener: (context, state) {
            if (state is CheckoutLoading) {
              // CupertinoActivityIndicator();
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
                message: "Failed to load checkout details",
              );
              print(state.error);
            }
          },
        ),
        BlocListener<ValidateOfferCubit, ValidateOfferState>(
          listener: (context, state) {
            if (state is ValidateOfferSuccess) {
              final res = state.validateOfferModel;

              final isSuccess = (res.status ?? '').toUpperCase() == 'SUCCESS';
              final saysTrue = (res.data ?? '').toLowerCase() == 'true' ||
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
                  message: res.data ?? "Coupon is not valid",
                );
                setState(() {
                  _isCouponApplied = false;
                });
                () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('offer_applied');
                  await prefs.remove('is_offer_flow');
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
                await prefs.remove('offer_coupon');
                await prefs.remove('offer_started_at');
                await prefs.remove('offer_applied');
              }();

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => const DashboardScreen(isGuest: false),
                  ),
                  (route) => false,
                );
              });
            } else if (state is PaymentFailure) {
              CustomSnackbars.showErrorSnack(
                context: context,
                title: 'Failed',
                message: "payment Failed",
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
            await prefs.remove('offer_coupon');
            await prefs.remove('offer_started_at');
          }();

          final updatedCart = <int, int>{};
          for (var item in selectedItems) {
            final productId = item['productId'] ?? item['id'];
            final qty = cart[item['name']] ?? 0;
            if (qty > 0) updatedCart[productId] = qty;
          }

          Navigator.pop(context, {
            'updatedCart': updatedCart,
            'cartItemsLength': getCartItemCount()
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
                await prefs.remove('offer_coupon');
                await prefs.remove('offer_started_at');
              }();
              final updatedCart = <int, int>{};
              for (var item in selectedItems) {
                final productId = item['productId'] ?? item['id'];
                final qty = cart[item['name']] ?? 0;
                if (qty > 0) updatedCart[productId] = qty;
              }

              Navigator.pop(context, {
                'updatedCart': updatedCart,
                'cartItemsLength': getCartItemCount()
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

                    final itemsPayload = selectedItems.map((item) {
                      final name = item['name'];
                      final quantity = cart[name] ?? 1;
                      return {
                        "productId": item['productId'] ?? item['id'],
                        "quantity": quantity,
                        "price": item['price'] ?? 0,
                      };
                    }).toList();

                    final payload = {
                      "notes": notesController.text.trim(),
                      "selfOrder": selfOrder,
                      "items": itemsPayload,
                    };

                    await context
                        .read<ProductsAddToCartCubit>()
                        .addToCart(payload);

                    _refreshCheckout();
                  }
                },
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Checkbox(
                      value: selfOrder,
                      activeColor: AppColor.PrimaryColor,
                      onChanged: (val) {
                        setState(() => selfOrder = val ?? true);

                        final itemsPayload = selectedItems.map((item) {
                          final name = item['name'];
                          final quantity = cart[name] ?? 1;
                          return {
                            "productId": item['productId'] ?? item['id'],
                            "quantity": quantity,
                            "price": item['price'] ?? 0,
                          };
                        }).toList();

                        final payload = {
                          "notes": notesController.text.trim(),
                          "selfOrder": selfOrder,
                          "items": itemsPayload,
                        };

                        context
                            .read<ProductsAddToCartCubit>()
                            .addToCart(payload);

                        // _refreshCheckout();
                      },
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "Self Order (I'll pick it myself)",
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: InkWell(
                  onTap: () async {
                    final newNote = await showDialog<String>(
                      context: context,
                      builder: (context) => AlertDialog(
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
                            onPressed: () => Navigator.pop(
                                context, notesController.text.trim()),
                            child: const Text("OK"),
                          ),
                        ],
                      ),
                    );
                    if (newNote != null) {
                      setState(() => notesController.text = newNote);

                      final List<Map<String, dynamic>> itemsPayload =
                          selectedItems.map((item) {
                        final name = item['name'];
                        final quantity = cart[name] ?? 1;
                        return {
                          "productId": item['productId'] ?? item['id'],
                          "quantity": quantity,
                          "price": item['price'] ?? 0,
                        };
                      }).toList();

                      final Map<String, dynamic> payload = {
                        "notes": notesController.text.trim(),
                        "selfOrder": selfOrder,
                        "items": itemsPayload,
                      };

                      context.read<ProductsAddToCartCubit>().addToCart(payload);
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
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.notes_rounded, color: Colors.orange),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            notesController.text.isEmpty
                                ? "Add delivery notes"
                                : notesController.text,
                            style: TextStyle(
                              color: notesController.text.isEmpty
                                  ? Colors.grey
                                  : Colors.black,
                              fontStyle: notesController.text.isEmpty
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
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: couponController,
                        decoration: InputDecoration(
                          hintText: "Enter coupon code",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        _maybeAutoValidateOffer();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.PrimaryColor,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("Apply"),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: selectedItems.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
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
                                      color: Colors.white, fontSize: 16),
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
                            return CartItemCard(
                              item: item,
                              quantity: cart[item['name']] ?? 1,
                              onQuantityChanged: (q) async {
                                setState(() {
                                  if (q <= 0) {
                                    cart.remove(item['name']);
                                    selectedItems.removeAt(i);
                                  } else {
                                    cart[item['name']] = q;
                                  }
                                });
                                final isCartEmpty = selectedItems.isEmpty;

                                if (isCartEmpty) {
                                  await context
                                      .read<ClearCartCubit>()
                                      .clearCart(context);
                                  await context
                                      .read<GetCartCubit>()
                                      .fetchCart(context);
                                } else {
                                  final List<Map<String, dynamic>>
                                      itemsPayload = selectedItems.map((item) {
                                    final name = item['name'];
                                    final quantity = cart[name] ?? 1;
                                    return {
                                      "productId":
                                          item['productId'] ?? item['id'],
                                      "quantity": quantity,
                                      "price": item['price'] ?? 0,
                                    };
                                  }).toList();

                                  final Map<String, dynamic> payload = {
                                    "notes": notesController.text.trim(),
                                    "items": itemsPayload,
                                  };

                                  context
                                      .read<ProductsAddToCartCubit>()
                                      .addToCart(payload);

                                  context
                                      .read<GetCartCubit>()
                                      .fetchCart(context);

                                  // Refresh checkout after quantity change
                                  _refreshCheckout();
                                }

                                widget.onBottomSheetVisibilityChanged
                                    ?.call(cart.isNotEmpty);
                              },
                            );
                          } else {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 20, horizontal: 16),
                              child: _checkoutLoading
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
                                      deliveryCharge: _isCouponApplied
                                          ? 0
                                          : _deliveryCharge,
                                      total:
                                          _isCouponApplied ? 1.0 : _grandTotal,
                                      loading: loading,
                                      onPlaceOrder: openCheckOut,
                                    ),
                            );
                          }
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
