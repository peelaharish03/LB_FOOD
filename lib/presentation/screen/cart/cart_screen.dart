import 'dart:convert';
import 'package:local_basket/presentation/cubit/cart/clearCart/clearCart_cubit.dart';
import 'package:local_basket/presentation/cubit/offers/restaurant_offers/validate_offers/validate_offer_cubit.dart';
import 'package:local_basket/presentation/cubit/offers/restaurant_offers/validate_offers/validate_offer_state.dart';
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
import 'package:local_basket/presentation/cubit/payment/payment_cubit.dart';
import 'package:local_basket/presentation/cubit/payment/payment_state.dart';
import 'package:local_basket/presentation/screen/address/address_screen.dart';

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


  final Map<String, int> cart = {};
  final List<Map<String, dynamic>> selectedItems = [];
  int? cartId;
  bool loading = false;
  String selectedAddress = "Add Address";
  bool selfOrder = true; 


  static const double gstPercentage = 0.05;
  static const double deliveryCharge = 30.0;

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
  }

  void _onPaymentSuccess(PaymentSuccessResponse response) async {
    final payload = {
      "cartId": cartId ?? 0,
      "amount": getTotalAmount(),
      "paymentId": response.paymentId,
      "razorpayOrderId": response.orderId,
      "razorpaySignature": response.signature,
      "status": "SUCCESS"
    };
    setState(() => loading = true);
    await context.read<PaymentCubit>().makePayment(payload, context);
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

  double getSubtotal() => selectedItems.fold(0.0, (sum, item) {
        final qty = cart[item['name']] ?? 0;
        final price = item['price'];
        final double val =
            price is String ? double.tryParse(price) ?? 0 : (price ?? 0.0);
        return sum + (qty * val);
      });

  double getGSTAmount() => getSubtotal() * gstPercentage;
  double getTotalAmount() {
    if (_isCouponApplied) return 1.0;
    return (getSubtotal() + getGSTAmount() + deliveryCharge).floorToDouble();
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
          message: "Select delivery address first");
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
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        foregroundColor: Colors.black87,
                      ),
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Cancel"),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.PrimaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        "I Understand, Proceed",
                        style: TextStyle(fontSize: 16, color: Colors.white),
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

    final amountInPaise = (getTotalAmount() * 100).toInt();
    final orderResp = await _createOrder(amountInPaise);
    if (orderResp["status"] != "success") {
      CustomSnackbars.showErrorSnack(
          context: context, title: 'ERROR', message: 'Payment gateway error');
      return;
    }

    _razorpay.open({
      'key': razorPayKey,
      'amount': amountInPaise,
      'name': 'local_basket',
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
            }
          },
        ),
        BlocListener<GetCartCubit, GetCartState>(
          listener: (context, state) {
            if (state is GetCartLoaded) {
              setState(() {
                cartId = state.cart.id;
                // pull existing notes & selfOrder from API
                notesController.text = state.cart.notes ?? "";
                selfOrder = state.cart.selfOrder ?? true;
              });
            }
          },
        ),

        BlocListener<ValidateOfferCubit, ValidateOfferState>(
          listener: (context, state) {
            if (state is ValidateOfferSuccess) {
              final res = state.validateOfferModel;

              if (res.message?.toLowerCase() == "true") {
                CustomSnackbars.showSuccessSnack(
                  context: context,
                  title: "Coupon Applied",
                  message: "Offer applied successfully!",
                );
                setState(() {
                  _isCouponApplied = true;
                });
              } else {
                CustomSnackbars.showErrorSnack(
                  context: context,
                  title: "Offer Expired",
                  message: res.data ?? "Coupon is not valid",
                );
                setState(() {
                  _isCouponApplied = false;
                });
              }
            } else if (state is ValidateOfferFailure) {
              CustomSnackbars.showErrorSnack(
                context: context,
                title: "Error",
                message: state.error,
              );
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
      child: Scaffold(
        backgroundColor: AppColor.White,
        appBar: CustomAppBar(
          title: "Cart (${getCartItemCount()} items)",
          onBackPressed: () {
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
                }
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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

                      context.read<ProductsAddToCartCubit>().addToCart(payload);
                    },
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Self Order (I’ll pick it myself)",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                      context.read<ValidateOfferCubit>().validateOffer();
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
                  ? const Center(child: Text("No items in cart"))
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
                                final List<Map<String, dynamic>> itemsPayload =
                                    selectedItems.map((item) {
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

                                context.read<GetCartCubit>().fetchCart(context);
                              }

                              widget.onBottomSheetVisibilityChanged
                                  ?.call(cart.isNotEmpty);
                            },
                          );
                        } else {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 20, horizontal: 16),
                                
                            child: CheckoutBottomBar(
                              subtotal: getSubtotal(),
                              gst: getGSTAmount(),
                              deliveryCharge: deliveryCharge,
                              total: getTotalAmount(),
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
    );
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }
}
