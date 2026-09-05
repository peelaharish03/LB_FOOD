import 'package:local_basket/components/custom_button.dart' as local_basket_button;
import 'package:flutter/material.dart';

class CheckoutBottomBar extends StatefulWidget {
  /// Price of the products only (cart items total), always visible.
  final double itemTotal;

  /// Charges hidden behind the down-arrow until expanded.
  final double deliveryCharge;
  final double tax;
  final double discount;

  /// Grand total, always visible.
  final double total;
  final bool loading;

  /// Fires when the buyer taps "Place Order". The payment method to use is
  /// chosen in the payment-method dropdown on the cart screen, so this bar
  /// no longer branches its own label on COD vs online.
  final VoidCallback onPlaceOrder;

  const CheckoutBottomBar({
    super.key,
    required this.itemTotal,
    required this.deliveryCharge,
    required this.tax,
    required this.discount,
    required this.total,
    required this.loading,
    required this.onPlaceOrder,
  });

  @override
  State<CheckoutBottomBar> createState() => _CheckoutBottomBarState();
}

class _CheckoutBottomBarState extends State<CheckoutBottomBar> {
  bool _expanded = false;

  Widget _buildPriceRow(
    String label,
    double value, {
    bool isTotal = false,
    bool negative = false,
  }) {
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
            "${negative ? '-' : ''}₹${value.toStringAsFixed(2)}",
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

  Widget _buildItemTotalRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            "Item Total",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Icon(
                _expanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                size: 22,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          const Spacer(),
          Text(
            "₹${widget.itemTotal.toStringAsFixed(2)}",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharges() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPriceRow("Delivery Charge", widget.deliveryCharge),
        _buildPriceRow("Taxes & Fees", widget.tax),
        if (widget.discount > 0)
          _buildPriceRow("Discount", widget.discount, negative: true),
      ],
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
                  _buildItemTotalRow(),
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 200),
                    crossFadeState: _expanded
                        ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
                    firstChild: _buildCharges(),
                    secondChild: const SizedBox(width: double.infinity),
                  ),
                  const Divider(height: 24, thickness: 1),
                  _buildPriceRow("Total", widget.total, isTotal: true),
                ],
              ),
            ),

            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: local_basket_button.CustomButton(
                buttonText: "Place Order",
                onPressed: widget.onPlaceOrder,
                isLoading: widget.loading,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
