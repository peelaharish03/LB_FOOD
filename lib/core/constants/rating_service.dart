import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_basket/data/model/orders/orderHistory/orderHistory_model.dart';
import 'package:local_basket/presentation/cubit/rating&reviews/rating&review_cubit.dart';
import 'package:local_basket/presentation/cubit/rating&reviews/rating&review_state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_navigator.dart';

class RatingService {
  static final RatingService _instance = RatingService._internal();
  factory RatingService() => _instance;
  RatingService._internal();

  bool _isDialogOpen = false;
  final Set<String> _promptedThisSession = <String>{};

  Future<void> checkAndShowRatingPopup({
    required BuildContext context,
    required List<Content> orders,
  }) async {
    if (_isDialogOpen) return;

    for (var order in orders) {
      final status = (order.orderStatus ?? '').trim().toUpperCase();
      if (status == 'DELIVERED') {
        final deliveryTime = order.updatedDate ?? order.createdDate;
        final now = DateTime.now();

        final eligible = deliveryTime == null
            ? true
            : now.difference(deliveryTime).inMinutes >= 20;

        if (eligible) {
          final orderId = order.orderNumber ?? '';
          if (orderId.isEmpty) continue;
          final isRated = await hasRated(orderId);
          final alreadyPrompted = _promptedThisSession.contains(orderId);
          debugPrint('[RatingService] Checking order $orderId | rated=$isRated, promptedThisSession=$alreadyPrompted');
          if (!isRated && !alreadyPrompted) {
            _promptedThisSession.add(orderId);
            _isDialogOpen = true;
            await showRatingDialog(context: context, order: order);
            _isDialogOpen = false;
            // Double-check after dialog close in case state changed
            final nowRated = await hasRated(orderId);
            if (nowRated) {
              _promptedThisSession.remove(orderId);
            }
            break;
          }
        }
      }
    }
  }

  Future<void> showRatingDialog(
      {required BuildContext context, required Content order}) {
    double rating = 0;
    final TextEditingController feedbackController = TextEditingController();

    final navContext = AppNavigator.key.currentContext ?? context;

    return showDialog(
      context: navContext,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
              "Rate your order from ${order.businessName ?? "restaurant"}"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("How was your experience?"),
              SizedBox(height: 12),
              StatefulBuilder(
                builder: (context, setState) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          rating > index ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                        ),
                        onPressed: () {
                          setState(() {
                            rating = index + 1.0;
                          });
                        },
                      );
                    }),
                  );
                },
              ),
              TextField(
                controller: feedbackController,
                decoration: InputDecoration(
                  hintText: 'Leave feedback (optional)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Later"),
            ),
            ElevatedButton(
              onPressed: () async {
                // Basic validation
                if (rating <= 0) {
                  ScaffoldMessenger.of(AppNavigator.key.currentContext ?? context)
                      .showSnackBar(
                    SnackBar(content: Text("Please select a rating.")),
                  );
                  return;
                }

                // Build payload per provided example (PRODUCT level)
                final payload = <String, dynamic>{
                  "businessId": order.businessId,
                  "productId": order.orderItems.isNotEmpty
                      ? order.orderItems.first.productId
                      : null,
                  "type": "PRODUCT",
                  "rating": rating,
                  "comment": feedbackController.text.trim(),
                }..removeWhere((key, value) => value == null);

                try {
                  final cubit = (AppNavigator.key.currentContext ?? context)
                      .read<RatingReviewCubit>();
                  await cubit.submitRatingReview(payload);
                  final state = cubit.state;
                  if (state is RatingReviewSuccess) {
                    final orderId = order.orderNumber ?? '';
                    if (orderId.isNotEmpty) {
                      await markRated(orderId);
                      _promptedThisSession.remove(orderId);
                    }
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(AppNavigator.key.currentContext ??
                              context)
                          .showSnackBar(
                        SnackBar(content: Text("Thanks for your feedback!")),
                      );
                    }
                  } else if (state is RatingReviewFailure) {
                    ScaffoldMessenger.of(AppNavigator.key.currentContext ??
                            context)
                        .showSnackBar(
                      SnackBar(content: Text(state.errorMessage)),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(AppNavigator.key.currentContext ??
                          context)
                      .showSnackBar(
                    SnackBar(content: Text("Failed to submit review")),
                  );
                }
              },
              child: Text("Submit"),
            ),
          ],
        );
      },
    );
  }

  Future<bool> hasRated(String orderId) async {
    final prefs = await SharedPreferences.getInstance();
    if (orderId.isEmpty) return false;
    final ratedKey = 'rating_v2_$orderId';
    final value = prefs.getBool(ratedKey) ?? false;
    debugPrint('[RatingService] hasRated($orderId) => $value (key: $ratedKey)');
    return value;
  }

  Future<void> markRated(String orderId) async {
    final prefs = await SharedPreferences.getInstance();
    if (orderId.isEmpty) return;
    final ratedKey = 'rating_v2_$orderId';
    await prefs.setBool(ratedKey, true);
    debugPrint('[RatingService] markRated($orderId) saved true to key: $ratedKey');
  }
}
