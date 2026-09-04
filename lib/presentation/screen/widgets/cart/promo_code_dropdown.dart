import 'package:local_basket/data/model/cart/eligiblePromotions/eligiblePromotions_model.dart';
import 'package:local_basket/presentation/screen/widgets/cart/cart_select_field.dart';
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

    final List<DropdownMenuItem<String>> items = !enabled
        ? [
            DropdownMenuItem<String>(
              enabled: false,
              child: Text(
                disabledHint,
                style: const TextStyle(color: Colors.white70),
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
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        "Checking available promo codes...",
                        style: TextStyle(color: Colors.white70),
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
                        child: Row(
                          children: [
                            const Icon(Icons.local_offer_rounded, size: 16),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                promo.description?.trim().isNotEmpty == true
                                    ? "${promo.displayLabel} — ${promo.description}"
                                    : promo.displayLabel,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList()
                : const [
                    DropdownMenuItem<String>(
                      enabled: false,
                      child: Text(
                        "No promo codes available",
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ];

    return CartSelectField(
      icon: Icons.local_offer_outlined,
      label: "Promo code",
      hint: enabled ? "Select a promo code" : disabledHint,
      value: enabled ? selectedPromoCode : null,
      items: items,
      // Keep the field tappable even with nothing to pick, so opening it is
      // what reveals "No promo codes available" rather than it just being
      // greyed out. Only fully disable it before a payment method is chosen.
      onChanged: !enabled
          ? null
          : (hasPromoCodes && !loading ? onChanged : (_) {}),
    );
  }
}
