import 'package:flutter/material.dart';
import 'package:local_basket/core/constants/colors.dart';
import 'package:local_basket/data/model/payment/paymentMethods/payment_methods_model.dart';

/// Payment-method selector shown below the promo-code dropdown in the cart.
/// Lists the active methods returned by the payment-methods API by name; the
/// chosen method's `code` is what gets sent to checkout as `paymentMethod`.
class PaymentMethodDropdown extends StatelessWidget {
  final List<PaymentMethod> methods;
  final bool loading;
  final String? selectedCode;
  final ValueChanged<String?> onChanged;

  const PaymentMethodDropdown({
    super.key,
    required this.methods,
    required this.loading,
    required this.selectedCode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasMethods = methods.isNotEmpty;

    final items = loading
        ? const [
            DropdownMenuItem<String>(
              enabled: false,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 10),
                  Text(
                    "Loading payment methods...",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ]
        : hasMethods
            ? methods
                .map(
                  (method) => DropdownMenuItem<String>(
                    value: method.checkoutCode,
                    child: Text(
                      method.description?.trim().isNotEmpty == true
                          ? "${method.displayName} — ${method.description}"
                          : method.displayName,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList()
            : const [
                DropdownMenuItem<String>(
                  enabled: false,
                  child: Text(
                    "No payment methods available",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: selectedCode,
        isExpanded: true,
        hint: const Text("Select a payment method"),
        icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColor.PrimaryColor),
        decoration: const InputDecoration(
          border: InputBorder.none,
          prefixIcon: Icon(Icons.account_balance_wallet_outlined),
          labelText: "Payment Method",
        ),
        items: items,
        onChanged: hasMethods && !loading ? onChanged : (_) {},
      ),
    );
  }
}
