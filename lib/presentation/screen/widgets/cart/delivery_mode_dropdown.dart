import 'package:flutter/material.dart';
import 'package:local_basket/core/constants/colors.dart';
import 'package:local_basket/data/model/payment/deliveryModes/delivery_modes_model.dart';

/// Delivery-mode selector shown above the promo-code dropdown in the cart.
/// Only rendered when the delivery-modes API returns more than one active
/// mode — a single mode is applied silently as `shippingMethod`.
class DeliveryModeDropdown extends StatelessWidget {
  final List<DeliveryMode> modes;
  final bool loading;
  final String? selectedCode;
  final ValueChanged<String?> onChanged;

  const DeliveryModeDropdown({
    super.key,
    required this.modes,
    required this.loading,
    required this.selectedCode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasModes = modes.isNotEmpty;

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
                    "Loading delivery modes...",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ]
        : hasModes
            ? modes
                .map(
                  (mode) => DropdownMenuItem<String>(
                    value: mode.checkoutCode,
                    child: Text(
                      mode.description?.trim().isNotEmpty == true
                          ? "${mode.displayName} — ${mode.description}"
                          : mode.displayName,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList()
            : const [
                DropdownMenuItem<String>(
                  enabled: false,
                  child: Text(
                    "No delivery modes available",
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
        hint: const Text("Select a delivery mode"),
        icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColor.PrimaryColor),
        decoration: const InputDecoration(
          border: InputBorder.none,
          prefixIcon: Icon(Icons.local_shipping_outlined),
          labelText: "Delivery Mode",
        ),
        items: items,
        onChanged: hasModes && !loading ? onChanged : (_) {},
      ),
    );
  }
}
