import 'package:local_basket/components/custom_button.dart' as local_basket_button;
import 'package:flutter/material.dart';

class CheckoutBottomBar extends StatelessWidget {
  final double subtotal;
  final double deliveryCharge;
  final double total;
  final bool loading;

  /// Fires when the buyer taps "Place Order". The payment method to use is
  /// chosen in the payment-method dropdown on the cart screen, so this bar
  /// no longer branches its own label on COD vs online.
  final VoidCallback onPlaceOrder;

  const CheckoutBottomBar({
    super.key,
    required this.subtotal,
    required this.deliveryCharge,
    required this.total,
    required this.loading,
    required this.onPlaceOrder,
  });

  Widget buildPriceRow(String label, double value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
              color: isTotal ? Colors.black : Colors.grey.shade700,
            ),
          ),
          Text(
            "₹${value.toStringAsFixed(2)}",
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
              color: isTotal ? Colors.black : Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.98),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FA),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildPriceRow("Subtotal", subtotal),
                  buildPriceRow("Delivery Charge", deliveryCharge),
                  const Divider(height: 24, thickness: 1),
                  buildPriceRow("Total", total, isTotal: true),
                ],
              ),
            ),

            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: local_basket_button.CustomButton(
                buttonText: "Place Order",
                onPressed: onPlaceOrder,
                isLoading: loading,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
