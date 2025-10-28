import 'package:local_basket/core/constants/colors.dart';
import 'package:local_basket/presentation/cubit/cart/clearCart/clearCart_cubit.dart';
import 'package:local_basket/presentation/cubit/cart/getCart/getCart_cubit.dart';
import 'package:local_basket/presentation/cubit/cart/getCart/getCart_state.dart';
import 'package:flutter/material.dart';
import 'package:local_basket/data/model/restaurants/guestMenuByRestaurantId/menu_content_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class MenuItemWidget extends StatefulWidget {
  final Content item;
  final int quantity;
  final bool isCouponFlow; // <--- add this

  final dynamic restaurantId;
  final String? restaurantName;
  final Function(int) onQuantityChanged;
  final bool isGuest;
  final VoidCallback? onGuestAttempt;

  const MenuItemWidget({
    super.key,
    required this.item,
    required this.quantity,
    required this.onQuantityChanged,
    required this.restaurantId,
    this.restaurantName,
    this.isGuest = false,
    this.onGuestAttempt,
    this.isCouponFlow = false,
  });

  @override
  State<MenuItemWidget> createState() => _MenuItemWidgetState();
}

class _MenuItemWidgetState extends State<MenuItemWidget> {
  late int quantity;
  bool showItem = true;
  String? comingSoonText;
  bool isBeforeStartTime = false;

  @override
  void initState() {
    super.initState();
    quantity = widget.quantity;
  }

  bool computeVisibility(Content item) {
    comingSoonText = null;
    isBeforeStartTime = false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    String? startTime;
    String? endTime;

    for (var attr in item.attributes) {
      if (attr.attributeName?.toLowerCase() == 'starttime') {
        startTime = attr.attributeValue;
      } else if (attr.attributeName?.toLowerCase() == 'endtime') {
        endTime = attr.attributeValue;
      }
    }

    if (item.available == true) {
      if (startTime != null) {
        final parts = startTime.split(':');
        if (parts.length >= 2) {
          final start = DateTime(
            today.year,
            today.month,
            today.day,
            int.parse(parts[0]),
            int.parse(parts[1]),
          );

          if (now.isBefore(start)) {
            isBeforeStartTime = true;
            final time = TimeOfDay.fromDateTime(start);
            comingSoonText = 'Available after ${time.format(context)}';
          }
        }
      }
      return true;
    }

    if (endTime != null) {
      final parts = endTime.split(':');
      if (parts.length >= 2) {
        final end = DateTime(
          today.year,
          today.month,
          today.day,
          int.parse(parts[0]),
          int.parse(parts[1]),
        );

        if (now.isBefore(end)) {
          isBeforeStartTime = true;
          final time = TimeOfDay.fromDateTime(end);
          comingSoonText = 'Available after ${time.format(context)}';
          return true;
        } else {
          return false;
        }
      }
    }

    return false;
  }

  void updateQuantity(int newQty) async {
    setState(() => quantity = newQty);
    widget.onQuantityChanged(newQty);

    if (newQty == 0) {
      final cartState = context.read<GetCartCubit>().state;
      final cartData = cartState is GetCartLoaded ? cartState.cart : null;
      final totalItems = cartData?.cartItems
              .fold<int>(0, (sum, item) => sum + (item.quantity ?? 0)) ??
          0;

      if (totalItems <= 1) {
        await context.read<ClearCartCubit>().clearCart(context);
        await context.read<GetCartCubit>().fetchCart(context);
      }
    }
  }

  void _handleAdd(cartData, String? cartBusinessId) async {
    if (widget.isGuest) {
      widget.onGuestAttempt?.call();
      return;
    }

    if (cartData != null &&
        cartData.cartItems?.isNotEmpty == true &&
        widget.restaurantId.toString() != cartBusinessId) {
      final shouldReplace = await showReplaceCartDialog(
        context: context,
        currentRestaurant: cartData.businessName ?? '',
        newRestaurant: widget.restaurantName ?? '',
      );
      if (shouldReplace != true) return;

      try {
        await context.read<ClearCartCubit>().clearCart(context);
        await context.read<GetCartCubit>().fetchCart(context);
        updateQuantity(1);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to clear cart: ${e.toString()}')),
        );
      }
    } else {
      updateQuantity(quantity + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    showItem = computeVisibility(widget.item);
    if (!showItem) return const SizedBox.shrink();

    final item = widget.item;
    final mediaUrl =
        item.media?.isNotEmpty == true ? item.media!.first.url : null;

    final typeAttr = item.attributes.firstWhere(
      (attr) => attr.attributeName?.toLowerCase() == 'type',
      orElse: () =>
          Attribute(id: null, attributeName: null, attributeValue: null),
    );
    final isVeg = typeAttr.attributeValue?.toLowerCase() == 'veg';

    final onlinePriceAttr = item.attributes.firstWhere(
      (attr) => attr.attributeName?.toLowerCase() == 'onlineprice',
      orElse: () =>
          Attribute(id: null, attributeName: null, attributeValue: null),
    );
    final priceText = onlinePriceAttr.attributeValue != null
        ? "₹${onlinePriceAttr.attributeValue}"
        : "₹${item.price ?? '0'}";

    final cartState = context.watch<GetCartCubit>().state;
    final cartData = cartState is GetCartLoaded ? cartState.cart : null;
    final cartBusinessId = cartData?.businessId?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isBeforeStartTime ? Colors.grey : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 140,
              width: 140,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (mediaUrl != null)
                    Positioned.fill(
                      child: Image.network(
                        mediaUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  if (isBeforeStartTime)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.5),
                        alignment: Alignment.center,
                        child: Text(
                          comingSoonText ?? "Coming Soon",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  Align(
                    alignment: mediaUrl == null
                        ? Alignment.center
                        : Alignment.bottomCenter,
                    child: Padding(
                      padding: mediaUrl != null
                          ? const EdgeInsets.only(bottom: 8.0)
                          : EdgeInsets.zero,
                      child: isBeforeStartTime || !(item.available ?? true)
                          ? Container(
                              height: 36,
                              alignment: Alignment.center,
                              child: Text(
                                comingSoonText ?? "Unavailable",
                                style: GoogleFonts.poppins(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            )
                          : quantity == 0
                              ? ElevatedButton(
                                  onPressed: () {
                                    if (widget.isCouponFlow) {
                                      // Coupon flow → force qty=1
                                      updateQuantity(1);
                                    } else {
                                      _handleAdd(cartData, cartBusinessId);
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  child: Text(
                                    "ADD",
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.green,
                                    ),
                                  ),
                                )
                              : Container(
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppColor.White,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 6),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          if (quantity > 0) {
                                            updateQuantity(quantity - 1);
                                          }
                                        },
                                        child: const Icon(Icons.remove,
                                            color: Colors.redAccent, size: 18),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12),
                                        child: Text(
                                          '$quantity',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          print(
                                              "><><<><<${widget.isCouponFlow}");
                                          if (widget.isCouponFlow) {
                                            // 🚫 disable increment beyond 1 in coupon flow
                                            return;
                                          }
                                          _handleAdd(cartData, cartBusinessId);
                                        },
                                        child: Icon(
                                          Icons.add,
                                          color: widget.isCouponFlow
                                              ? Colors
                                                  .grey // greyed out in coupon flow
                                              : AppColor.PrimaryColor,
                                          size: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    vegNonVegIcon(isVeg),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.name ?? '',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  priceText,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.green, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      "4.5",
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                  ],
                ),
                // if (comingSoonText != null) ...[
                //   const SizedBox(height: 4),
                //   Text(
                //     comingSoonText!,
                //     style: GoogleFonts.poppins(
                //       fontSize: 12,
                //       color: Colors.red,
                //       fontWeight: FontWeight.w500,
                //     ),
                //   ),
                // ],
                const SizedBox(height: 6),
                Text(
                  item.description ??
                      "Juicy meat on a stick, perfect for sharing. Serves 1–2",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<bool?> showReplaceCartDialog({
  required BuildContext context,
  required String currentRestaurant,
  required String newRestaurant,
}) async {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shopping_cart_outlined,
                size: 48, color: Colors.deepOrange),
            const SizedBox(height: 16),
            Text(
              'Replace items in your cart?',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'Your cart contains dishes from '),
                  TextSpan(
                    text: currentRestaurant,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  const TextSpan(
                      text: '.\n\nDo you want to discard and add items from '),
                  TextSpan(
                    text: newRestaurant,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  const TextSpan(text: '?'),
                ],
              ),
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black87,
                      side: const BorderSide(color: Colors.black26),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text("No"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text("Replace"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

Widget vegNonVegIcon(bool isVeg) {
  return Container(
    width: 16,
    height: 16,
    decoration: BoxDecoration(
      border: Border.all(color: isVeg ? Colors.green : Colors.red, width: 1.5),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Center(
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: isVeg ? Colors.green : Colors.red,
          shape: BoxShape.circle,
        ),
      ),
    ),
  );
}
