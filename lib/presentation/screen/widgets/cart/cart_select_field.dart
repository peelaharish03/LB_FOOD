import 'package:flutter/material.dart';
import 'package:local_basket/core/constants/colors.dart';

/// Shared visual shell for the cart selectors (payment method, promo code,
/// delivery mode). Renders an accent icon chip, a small caption label with the
/// current value / hint underneath, and a trailing chevron. The individual
/// widgets only build their `items` list and hand it here.
///
/// The open menu is painted in the app's header colour with white rows; the
/// closed field keeps a light branded tint so the selected value stays
/// readable.
class CartSelectField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String hint;
  final String? value;
  final List<DropdownMenuItem<String>> items;

  /// Null disables the control (greyed, not tappable).
  final ValueChanged<String?>? onChanged;

  const CartSelectField({
    super.key,
    required this.icon,
    required this.label,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // DropdownButton asserts the value matches exactly one item — guard so a
    // stale selection (e.g. while the list reloads) can't crash the screen.
    final String? safeValue =
        items.any((item) => item.value == value) ? value : null;
    final bool hasValue = safeValue != null && safeValue.isNotEmpty;
    final bool disabled = onChanged == null;
    final Color accent = AppColor.PrimaryColor;

    // Menu rows: force onto white so they read on the header-coloured menu.
    final menuItems = items
        .map(
          (item) => DropdownMenuItem<String>(
            value: item.value,
            enabled: item.enabled,
            alignment: item.alignment,
            child: DefaultTextStyle.merge(
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
              ),
              child: IconTheme.merge(
                data: const IconThemeData(color: Colors.white, size: 18),
                child: item.child,
              ),
            ),
          ),
        )
        .toList();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: disabled
            ? const Color(0xFFF4F5F7)
            : (hasValue ? accent.withOpacity(0.06) : Colors.white),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasValue ? accent.withOpacity(0.55) : const Color(0xFFE6E8EC),
          width: 1.3,
        ),
        boxShadow: disabled
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accent.withOpacity(disabled ? 0.06 : 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: disabled ? AppColor.Grey1 : accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10.5,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w700,
                    color: disabled ? AppColor.Grey1 : accent,
                  ),
                ),
                const SizedBox(height: 1),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: safeValue,
                    isExpanded: true,
                    isDense: true,
                    borderRadius: BorderRadius.circular(14),
                    dropdownColor: accent,
                    elevation: 3,
                    hint: Text(
                      hint,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColor.Grey1,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    icon: const SizedBox.shrink(),
                    // Closed field: dark text on the light field background.
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: AppColor.Black,
                    ),
                    selectedItemBuilder: (context) => items
                        .map(
                          (item) => Align(
                            alignment: Alignment.centerLeft,
                            child: IconTheme.merge(
                              data: IconThemeData(color: accent, size: 18),
                              child: item.child,
                            ),
                          ),
                        )
                        .toList(),
                    items: menuItems,
                    onChanged: onChanged,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            color: hasValue ? accent : AppColor.Grey1,
          ),
        ],
      ),
    );
  }
}
