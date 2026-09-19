import 'package:flutter/material.dart';
import 'package:local_basket/presentation/screen/widgets/cart/cart_select_field.dart';

/// Payment-method selector shown above the promo-code dropdown in the cart.
///
/// This is a fixed two-choice picker — Cash on Delivery or Online Payment —
/// and starts unselected so the buyer always makes an explicit choice. The
/// chosen value's code is what checkout branches on (`COD` → COD API,
/// `RAZORPAY` → Razorpay).
///
/// Which of the two choices actually show is gated by [eligibleCodes], the
/// result of the `GET /api/carts/{cartId}/eligible-payment-methods` check
/// (COD can drop out above certain order values, in certain zones, etc).
/// Null shows both — while that check is loading, failed, or hasn't run yet,
/// a missing eligibility answer must never itself block checkout.
class PaymentMethodDropdown extends StatelessWidget {
  static const String codCode = 'COD';
  static const String onlineCode = 'RAZORPAY';

  static const _options = [
    (code: codCode, icon: Icons.payments_outlined, label: "Cash on Delivery"),
    (
      code: onlineCode,
      icon: Icons.credit_card_rounded,
      label: "Online Payment",
    ),
  ];

  final String? selectedCode;
  final ValueChanged<String?> onChanged;

  /// True while the picked method is still being synced onto the cart
  /// (persisting it + refreshing promo codes/charges) — shown as a spinner
  /// on the field so switching methods doesn't look like it did nothing.
  final bool busy;

  final Set<String>? eligibleCodes;

  /// True while the eligibility check itself is in flight.
  final bool loading;

  const PaymentMethodDropdown({
    super.key,
    required this.selectedCode,
    required this.onChanged,
    this.busy = false,
    this.eligibleCodes,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final codes = eligibleCodes;
    final options = codes == null
        ? _options
        : _options.where((o) => codes.contains(o.code)).toList();

    final items = options.isNotEmpty
        ? options
              .map(
                (o) => DropdownMenuItem<String>(
                  value: o.code,
                  child: Row(
                    children: [
                      Icon(o.icon, size: 18),
                      const SizedBox(width: 10),
                      Text(o.label, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              )
              .toList()
        : const [
            DropdownMenuItem<String>(
              enabled: false,
              child: Text(
                "No payment methods available for this cart",
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ];

    return CartSelectField(
      icon: Icons.account_balance_wallet_outlined,
      label: "Payment method",
      hint: "Select payment method",
      value: options.any((o) => o.code == selectedCode) ? selectedCode : null,
      onChanged: options.isNotEmpty ? onChanged : (_) {},
      busy: busy || loading,
      items: items,
    );
  }
}
