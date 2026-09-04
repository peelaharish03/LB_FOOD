import 'package:flutter/material.dart';
import 'package:local_basket/data/model/payment/deliveryModes/delivery_modes_model.dart';
import 'package:local_basket/presentation/screen/widgets/cart/cart_select_field.dart';

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

    final List<DropdownMenuItem<String>> items = loading
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
                    "Loading delivery modes...",
                    style: TextStyle(color: Colors.white70),
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
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ];

    return CartSelectField(
      icon: Icons.local_shipping_outlined,
      label: "Delivery mode",
      hint: "Select a delivery mode",
      value: selectedCode,
      items: items,
      onChanged: hasModes && !loading ? onChanged : (_) {},
    );
  }
}
