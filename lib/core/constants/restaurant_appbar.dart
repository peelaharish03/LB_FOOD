import 'package:flutter/material.dart';
import 'package:local_basket/core/constants/colors.dart';

class SwiggyStyleAppBar extends StatelessWidget {
  final String restaurantName;
  final String location;
  final String deliveryTime;
  final double rating;
  final String offerText;
  final bool isBottomSheetVisible;
  final dynamic bottomSheetController;
  final List<dynamic> selectedItems;
  final Map<String, int> cart;
  final int totalItems;
  final bool showBackButton;
  final Future<void> Function()? onBackPressed;

  const SwiggyStyleAppBar({
    super.key,
    required this.restaurantName,
    required this.location,
    required this.deliveryTime,
    required this.rating,
    required this.offerText,
    required this.isBottomSheetVisible,
    required this.bottomSheetController,
    required this.selectedItems,
    required this.cart,
    required this.totalItems,
    this.showBackButton = true,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 🔶 Gradient Header with rounded bottom corners
        Container(
          height: 150 + topPadding,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColor.PrimaryColor.withValues(alpha: 0.95),
                AppColor.PrimaryColor.withValues(alpha: 0.65),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
        ),

        // ◀️ Back Button floating above card
        if (showBackButton)
          Positioned(
            top: topPadding + 8,
            left: 16,
            child: GestureDetector(
              onTap: () async {
                if (onBackPressed != null) {
                  await onBackPressed!();
                  return;
                }

                if (isBottomSheetVisible && bottomSheetController != null) {
                  bottomSheetController?.close();
                  await Future.delayed(const Duration(milliseconds: 300));
                }

                final updatedCart = <dynamic, int>{};
                for (var item in selectedItems) {
                  final productId = item.id;
                  final qty = cart[item.name] ?? 0;
                  if (qty > 0 && productId != null) {
                    updatedCart[productId] = qty;
                  }
                }

                if (context.mounted) {
                  Navigator.pop(context, {
                    'updatedCart': updatedCart,
                    'cartItemsLength': totalItems,
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),

        // 🍽️ Floating Restaurant Info Card
        Positioned(
          top: 120,
          left: 16,
          right: 16,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Partner + Rating Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.verified,
                            color: Colors.deepOrange, size: 16),
                        SizedBox(width: 5),
                        Text(
                          'Local Basket',
                          style: TextStyle(
                            color: Colors.deepOrange,
                            fontWeight: FontWeight.w600,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Text(
                            rating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(Icons.star, color: Colors.white, size: 13),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Restaurant Name
                Text(
                  restaurantName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    height: 1.2,
                  ),
                ),

                const SizedBox(height: 6),

                // Location + Time
                Row(
                  children: [
                    Icon(Icons.location_pin,
                        size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 3),
                    Text(
                      "$deliveryTime • $location",
                      style: TextStyle(
                        fontSize: 13.5,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Offer Tag
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_offer,
                          color: Colors.deepOrange, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        offerText,
                        style: const TextStyle(
                          color: Colors.deepOrange,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
