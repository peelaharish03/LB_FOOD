import 'package:local_basket/core/constants/colors.dart';
import 'package:local_basket/data/model/cart/eligiblePromotions/eligiblePromotions_model.dart';
import 'package:flutter/material.dart';

/// Promo-code selector shown above the cart items. Opens like a normal
/// dropdown; if the cart has no eligible promo codes, opening it shows a
/// single "No promo codes available" row instead of a blank menu.
class PromoCodeDropdown extends StatelessWidget {
  final List<EligiblePromotion> promoCodes;
  final bool loading;
  final String? selectedPromoCode;
  final ValueChanged<String?> onChanged;

  /// When false the field is disabled and shows a hint row — used until a
  /// payment method has been chosen, since eligible promos depend on it.
  final bool enabled;
  final String disabledHint;

  const PromoCodeDropdown({
    super.key,
    required this.promoCodes,
    required this.loading,
    required this.selectedPromoCode,
    required this.onChanged,
    this.enabled = true,
    this.disabledHint = "Select a payment method first",
  });

  @override
  Widget build(BuildContext context) {
    final hasPromoCodes = promoCodes.isNotEmpty;

    final items = !enabled
        ? [
            DropdownMenuItem<String>(
              enabled: false,
              child: Text(
                disabledHint,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          ]
        : loading
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
                    "Checking available promo codes...",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ]
        : hasPromoCodes
            ? promoCodes
                .map(
                  (promo) => DropdownMenuItem<String>(
                    value: promo.value,
                    child: Text(
                      promo.description?.trim().isNotEmpty == true
                          ? "${promo.displayLabel} — ${promo.description}"
                          : promo.displayLabel,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList()
            : const [
                DropdownMenuItem<String>(
                  enabled: false,
                  child: Text(
                    "No promo codes available",
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
        value: enabled ? selectedPromoCode : null,
        isExpanded: true,
        hint: Text(enabled ? "Select a promo code" : disabledHint),
        icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColor.PrimaryColor),
        decoration: const InputDecoration(
          border: InputBorder.none,
          prefixIcon: Icon(Icons.local_offer_outlined),
          labelText: "Promo Code",
        ),
        items: items,
        // Keep the field tappable even with nothing to pick, so opening it
        // is what reveals "No promo codes available" rather than the field
        // just being greyed out.
        onChanged:
            enabled && hasPromoCodes && !loading ? onChanged : (_) {},
      ),
    );
  }
}
