import 'package:flutter/material.dart';
import 'package:local_basket/core/constants/colors.dart';

/// Shown in the cart body when there are no items — the "Your cart is empty"
/// message with an "Add items" button that pops back to shopping.
class EmptyCartView extends StatelessWidget {
  final VoidCallback onAddItems;

  const EmptyCartView({super.key, required this.onAddItems});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Your cart is empty",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onAddItems,
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
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
