import 'package:flutter/material.dart';
import 'package:local_basket/data/model/orders/orderHistory/orderHistory_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RatingService {
  static final RatingService _instance = RatingService._internal();
  factory RatingService() => _instance;
  RatingService._internal();

  Future<void> checkAndShowRatingPopup({
    required BuildContext context,
    required List<Content> orders,
  }) async {
    for (var order in orders) {
      if (order.orderStatus?.toUpperCase() == 'DELIVERED' &&
          order.createdDate != null) {
        final deliveryTime = order.createdDate!;
        final now = DateTime.now();

        if (now.difference(deliveryTime).inMinutes >= 20) {
          final orderId = order.orderNumber ?? '';
          final isRated = await hasRated(orderId);
          if (!isRated) {
            await markRated(orderId);
            showRatingDialog(context: context, order: order);
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

    return showDialog(
      context: context,
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
                Navigator.pop(context);
                final orderId = order.orderNumber ?? '';
                await markRated(orderId);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Thanks for your feedback!")),
                );
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
    final ratedKey = 'rated_$orderId';
    return prefs.getBool(ratedKey) ?? false;
  }

  Future<void> markRated(String orderId) async {
    final prefs = await SharedPreferences.getInstance();
    if (orderId.isEmpty) return;
    final ratedKey = 'rated_$orderId';
    await prefs.setBool(ratedKey, true);
  }
}
