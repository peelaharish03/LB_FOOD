import 'package:local_basket/components/custom_button.dart' as local_basket_button;
import 'package:local_basket/core/constants/colors.dart';
import 'package:flutter/material.dart';

class CheckoutBottomBar extends StatefulWidget {
  /// Price of the products only (cart items total).
  final double itemTotal;

  /// Charges shown in the always-visible breakdown, straight from the cart.
  final double deliveryCharge;
  final double tax;

  /// Total discount as reported by the cart itself (`totalDiscount`).
  final double discount;

  /// Platform fee as reported by the cart itself (`platformFee`) — always
  /// shown, even when zero.
  final double platformFee;

  /// Grand total — always visible; tapping its arrow reveals the breakdown.
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
    required this.platformFee,
    required this.total,
    required this.loading,
    required this.onPlaceOrder,
  });

  @override
  State<CheckoutBottomBar> createState() => _CheckoutBottomBarState();
}

class _CheckoutBottomBarState extends State<CheckoutBottomBar> {
  bool _expanded = false;

  // Only a few lines are colour-coded; the rest stay neutral so the panel
  // doesn't look busy:
  //  • Delivery Charge / Platform Fee – red   (added charges)
  //  • Discount                       – green (money you save)
  //  • Total                          – header colour, bold
  static const Color _chargeColor = Color(0xFFE53935); // red 600
  static const Color _discountColor = Color(0xFF2E7D32); // green 800
  static const Color _neutralColor = Color(0xFF5A5A5A);

  Widget _buildPriceRow(
    String label,
    double value, {
    Color color = _neutralColor,
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
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          Text(
            "${negative ? '-' : ''}₹${value.toStringAsFixed(2)}",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// The itemised breakdown, revealed under the Total row when expanded.
  Widget _buildCharges() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPriceRow("Item Total", widget.itemTotal),
        _buildPriceRow(
          "Delivery Charge",
          widget.deliveryCharge,
          color: _chargeColor,
        ),
        _buildPriceRow("Taxes & Fees", widget.tax),
        if (widget.discount > 0)
          _buildPriceRow(
            "Discount",
            widget.discount,
            color: _discountColor,
            negative: true,
          ),
        _buildPriceRow(
          "Platform Fee",
          widget.platformFee,
          color: _chargeColor,
        ),
        const Divider(height: 24, thickness: 1),
      ],
    );
  }

  /// Always-visible Total row with the expand/collapse toggle for the
  /// breakdown above it.
  Widget _buildTotalRow() {
    final totalColor = AppColor.PrimaryColor;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            "Total",
            style: TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
              color: totalColor,
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
                color: totalColor,
              ),
            ),
          ),
          const Spacer(),
          Text(
            "₹${widget.total.toStringAsFixed(2)}",
            style: TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
              color: totalColor,
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
                  // Only the grand Total is shown by default; the itemised
                  // breakdown (item total, delivery, taxes, discount, platform
                  // fee — exactly as the cart reports them) drops down when the
                  // arrow on the Total row is tapped.
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 200),
                    crossFadeState: _expanded
                        ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
                    firstChild: _buildCharges(),
                    secondChild: const SizedBox(width: double.infinity),
                  ),
                  _buildTotalRow(),
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
