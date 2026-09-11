import 'package:local_basket/data/model/cart/eligiblePromotions/eligiblePromotions_model.dart';
import 'package:local_basket/presentation/screen/widgets/cart/cart_select_field.dart';
import 'package:flutter/material.dart';

/// Promo-code selector shown above the cart items. Opens like a normal
/// dropdown; if the cart has no eligible promo codes, opening it shows a
/// single "No promo codes available" row instead of a blank menu.
///
/// When a promo code is applied, a "Don't apply a promo code" row is added at
/// the top so the buyer can clear it again (which removes the coupon from the
/// cart).
class PromoCodeDropdown extends StatelessWidget {
  final List<EligiblePromotion> promoCodes;
  final bool loading;
  final String? selectedPromoCode;
  final ValueChanged<String?> onChanged;

  /// True while the cart-level coupon apply / remove request is in flight.
  final bool applying;

  /// When false the field is disabled and shows a hint row — used until a
  /// payment method has been chosen, since eligible promos depend on it.
  final bool enabled;
  final String disabledHint;

  /// Sentinel value for the "no promo code" row.
  static const String noneValue = '__none__';

  const PromoCodeDropdown({
    super.key,
    required this.promoCodes,
    required this.loading,
    required this.selectedPromoCode,
    required this.onChanged,
    this.applying = false,
    this.enabled = true,
    this.disabledHint = "Select a payment method first",
  });

  static DropdownMenuItem<String> _infoRow(String text) => DropdownMenuItem(
        enabled: false,
        child: Text(text, style: const TextStyle(color: Colors.white70)),
      );

  static DropdownMenuItem<String> _promoRow(String value, String label) =>
      DropdownMenuItem(
        value: value,
        child: Row(
          children: [
            const Icon(Icons.local_offer_rounded, size: 16),
            const SizedBox(width: 10),
            Expanded(child: Text(label, overflow: TextOverflow.ellipsis)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final hasPromoCodes = promoCodes.isNotEmpty;
    final selected = selectedPromoCode?.trim();
    final hasSelection = selected != null && selected.isNotEmpty;

    // A coupon already applied to the cart is shown (and can be changed /
    // removed) even before a payment method is picked — the applied code
    // doesn't depend on the eligible-promotions list.
    final active = enabled || hasSelection;
    final busy = active && (loading || applying);

    List<DropdownMenuItem<String>> items;
    if (!active) {
      items = [_infoRow(disabledHint)];
    } else if (loading && !hasSelection) {
      items = const [
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
      ];
    } else {
      items = [];
      // "Don't apply a promo code" — only when something is currently applied.
      if (hasSelection) {
        items.add(
          const DropdownMenuItem<String>(
            value: noneValue,
            child: Row(
              children: [
                Icon(Icons.block_rounded, size: 16),
                SizedBox(width: 10),
                Expanded(child: Text("Don't apply a promo code")),
              ],
            ),
          ),
        );
      }
      if (enabled && !loading) {
        for (final promo in promoCodes) {
          final label = promo.description?.trim().isNotEmpty == true
              ? "${promo.displayLabel} — ${promo.description}"
              : promo.displayLabel;
          items.add(_promoRow(promo.value, label));
        }
      }
      // The applied coupon commonly drops out of the eligible list once it's
      // on the cart — keep it selectable/visible so the field keeps showing it
      // through to checkout rather than snapping back to the hint.
      if (hasSelection && !items.any((i) => i.value == selected)) {
        items.add(_promoRow(selected, selected));
      }
      if (items.isEmpty) {
        items = [_infoRow(enabled ? "No promo codes available" : disabledHint)];
      }
    }

    // Picking is possible when there are eligible codes to choose from, or
    // when there's an applied code that can be cleared / re-picked.
    final canPick = active && !applying && !loading && (hasPromoCodes || hasSelection);

    return CartSelectField(
      icon: Icons.local_offer_outlined,
      label: "Promo code",
      hint: active ? "Select a promo code" : disabledHint,
      value: active ? selected : null,
      items: items,
      // Shown on the closed field itself, not just inside the opened menu,
      // so it doesn't look idle/unresponsive while promo codes are fetched
      // or a coupon apply / remove call is in flight.
      busy: busy,
      onChanged: !active
          ? null
          : (canPick
              ? (value) => onChanged(value == noneValue ? null : value)
              : (_) {}),
    );
  }
}
