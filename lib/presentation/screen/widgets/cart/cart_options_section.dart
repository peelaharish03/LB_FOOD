import 'package:flutter/material.dart';
import 'package:local_basket/data/model/cart/eligiblePromotions/eligiblePromotions_model.dart';
import 'package:local_basket/data/model/payment/deliveryModes/delivery_modes_model.dart';
import 'package:local_basket/presentation/screen/widgets/cart/delivery_mode_dropdown.dart';
import 'package:local_basket/presentation/screen/widgets/cart/payment_method_dropdown.dart';
import 'package:local_basket/presentation/screen/widgets/cart/promo_code_dropdown.dart';

/// The stack of selectors that sits between the address card and the item
/// list: payment method, delivery mode (only when more than one is active)
/// and promo code. Pure presentation — every value and callback is supplied
/// by [CartScreen].
class CartOptionsSection extends StatelessWidget {
  final String? selectedPaymentMethod;
  final bool paymentBusy;
  final ValueChanged<String?> onPaymentMethodChanged;

  final List<DeliveryMode> deliveryModes;
  final bool deliveryModesLoading;
  final String? deliveryDropdownValue;
  final ValueChanged<String?> onDeliveryModeChanged;

  final List<EligiblePromotion> promoCodes;
  final bool promotionsLoading;
  final bool promoApplying;
  final String? selectedPromoCode;
  final ValueChanged<String?> onPromoCodeChanged;

  const CartOptionsSection({
    super.key,
    required this.selectedPaymentMethod,
    required this.paymentBusy,
    required this.onPaymentMethodChanged,
    required this.deliveryModes,
    required this.deliveryModesLoading,
    required this.deliveryDropdownValue,
    required this.onDeliveryModeChanged,
    required this.promoCodes,
    required this.promotionsLoading,
    required this.promoApplying,
    required this.selectedPromoCode,
    required this.onPromoCodeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Payment dropdown is always shown while the cart has items (even in
        // the coupon / COD-only flows, where checkout still forces COD
        // regardless of the pick).
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: PaymentMethodDropdown(
            selectedCode: selectedPaymentMethod,
            busy: paymentBusy,
            onChanged: onPaymentMethodChanged,
          ),
        ),
        // Delivery-mode dropdown is only shown when the API returns more than
        // one active mode; a single mode is applied silently.
        if (deliveryModes.length > 1)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: DeliveryModeDropdown(
              modes: deliveryModes,
              loading: deliveryModesLoading,
              selectedCode: deliveryDropdownValue,
              onChanged: onDeliveryModeChanged,
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: PromoCodeDropdown(
            promoCodes: promoCodes,
            loading: promotionsLoading,
            applying: promoApplying,
            selectedPromoCode: selectedPromoCode,
            enabled: selectedPaymentMethod != null,
            onChanged: onPromoCodeChanged,
          ),
        ),
      ],
    );
  }
}
