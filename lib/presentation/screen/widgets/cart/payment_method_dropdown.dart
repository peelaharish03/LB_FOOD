import 'package:flutter/material.dart';
import 'package:local_basket/presentation/screen/widgets/cart/cart_select_field.dart';

/// Payment-method selector shown above the promo-code dropdown in the cart.
///
/// This is a fixed two-choice picker — Cash on Delivery or Online Payment —
/// and starts unselected so the buyer always makes an explicit choice. The
/// chosen value's code is what checkout branches on (`COD` → COD API,
/// `RAZORPAY` → Razorpay).
class PaymentMethodDropdown extends StatelessWidget {
  static const String codCode = 'COD';
  static const String onlineCode = 'RAZORPAY';

  final String? selectedCode;
  final ValueChanged<String?> onChanged;

  const PaymentMethodDropdown({
    super.key,
    required this.selectedCode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CartSelectField(
      icon: Icons.account_balance_wallet_outlined,
      label: "Payment method",
      hint: "Select payment method",
      value: selectedCode,
      onChanged: onChanged,
      items: const [
        DropdownMenuItem<String>(
          value: codCode,
          child: Row(
            children: [
              Icon(Icons.payments_outlined, size: 18),
              SizedBox(width: 10),
              Text("Cash on Delivery", overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        DropdownMenuItem<String>(
          value: onlineCode,
          child: Row(
            children: [
              Icon(Icons.credit_card_rounded, size: 18),
              SizedBox(width: 10),
              Text("Online Payment", overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}
