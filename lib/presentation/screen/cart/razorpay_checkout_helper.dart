import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:local_basket/data/model/payment/checkout_model.dart';

/// Pure helpers for the Razorpay leg of cart checkout — string tidying, the
/// static UPI-first block config and the checkout-options map. Kept free of
/// widget state so [CartScreen] just feeds in the values it already has.
class RazorpayCheckoutHelper {
  RazorpayCheckoutHelper._();

  static String? trimmedOrNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  static String? firstNonEmpty(String? primary, String fallback) {
    final primaryValue = primary?.trim();
    if (primaryValue != null && primaryValue.isNotEmpty) return primaryValue;

    final fallbackValue = fallback.trim();
    return fallbackValue.isEmpty ? null : fallbackValue;
  }

  static String? formattedContact(String? value) {
    final trimmed = trimmedOrNull(value);
    if (trimmed == null) return null;
    if (trimmed.startsWith('+')) return trimmed;

    final digitsOnly = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length == 10) return '+91$digitsOnly';
    if (digitsOnly.length == 12 && digitsOnly.startsWith('91')) {
      return '+$digitsOnly';
    }
    return digitsOnly.isEmpty ? trimmed : digitsOnly;
  }

  static String maskKey(String key) {
    final trimmed = key.trim();
    if (trimmed.length <= 8) return '****';
    return '${trimmed.substring(0, 8)}...'
        '${trimmed.substring(trimmed.length - 4)}';
  }

  static int amountInPaise(CheckoutModel checkout, double fallbackAmount) {
    final amount =
        checkout.totalAmount ?? checkout.data?.grandTotal ?? fallbackAmount;
    return (amount * 100).round();
  }

  static String formatFailure(dynamic response) {
    if (response is PaymentFailureResponse) {
      final details = <String>[];
      final message = response.message?.trim();
      final code = response.code;
      final error = response.error;
      final reason = error?['reason']?.toString().trim();
      final description = error?['description']?.toString().trim();

      if (message != null && message.isNotEmpty) details.add(message);
      if (code != null) details.add('Code: $code');
      if (reason != null && reason.isNotEmpty && reason != message) {
        details.add('Reason: $reason');
      }
      if (description != null &&
          description.isNotEmpty &&
          description != message) {
        details.add(description);
      }

      return details.isEmpty ? 'Payment failed' : details.join('\n');
    }

    final message = response?.toString().trim();
    return message == null || message.isEmpty ? 'Payment failed' : message;
  }

  static Map<String, dynamic> upiFirstConfig() {
    return {
      'display': {
        'blocks': {
          'upi_apps': {
            'name': 'Pay via UPI',
            'instruments': [
              {'method': 'upi'},
            ],
          },
          'other_methods': {
            'name': 'Cards, Wallets & Netbanking',
            'instruments': [
              {'method': 'card'},
              {'method': 'wallet'},
              {'method': 'netbanking'},
            ],
          },
        },
        'sequence': ['block.upi_apps', 'block.other_methods'],
        'preferences': {'show_default_blocks': true},
      },
    };
  }

  static Map<String, dynamic> notesFor(CheckoutModel checkout, String? cartId) {
    final notes = <String, dynamic>{};

    void addNote(String key, Object? value) {
      final text = value?.toString().trim();
      if (text != null && text.isNotEmpty) notes[key] = text;
    }

    addNote('appOrderId', checkout.orderId);
    addNote('razorpayOrderId', checkout.razorpayOrderId);
    addNote('orderStatus', checkout.orderStatus);
    addNote('paymentStatus', checkout.paymentStatus);
    addNote('fraudFlagged', checkout.fraudFlagged);
    addNote('cartId', cartId);
    if (checkout.crossSellProductIds.isNotEmpty) {
      addNote('crossSellProductIds', checkout.crossSellProductIds.join(','));
    }

    return notes;
  }

  static Map<String, dynamic> checkoutOptions({
    required String key,
    required int amountInPaise,
    required String razorpayOrderId,
    required Map<String, dynamic> prefill,
    required Map<String, dynamic> notes,
  }) {
    return {
      'key': key,
      'amount': amountInPaise,
      'currency': 'INR',
      'name': 'Local Basket',
      'order_id': razorpayOrderId,
      'method': 'upi',
      'description': 'Cart Payment',
      'prefill': prefill,
      'notes': notes,
      'config': upiFirstConfig(),
      'retry': {'enabled': true, 'max_count': 1},
      'timeout': 60,
      'theme': {'color': '#081724'},
    };
  }
}
