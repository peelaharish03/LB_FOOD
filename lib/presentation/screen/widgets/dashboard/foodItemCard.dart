import 'package:local_basket/core/constants/colors.dart';
import 'package:local_basket/core/constants/img_const.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class FoodItemCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final Function(String restaurantName)? onRestaurantTap;
  final Function()? onReorder;
  final Function()? onViewDetails;
  final List<String> mediaUrls;
  final bool isActive;

  const FoodItemCard({
    super.key,
    required this.data,
    this.onRestaurantTap,
    this.onReorder,
    this.onViewDetails,
    this.mediaUrls = const [],
    this.isActive = true,
  });

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildRatingStars(double rating) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < rating.floor()
              ? Icons.star_rounded
              : Icons.star_border_rounded,
          color: Colors.amber,
          size: 18,
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isInactive = !isActive;
    return GestureDetector(
      onTap: isInactive
          ? null
          : () => onRestaurantTap?.call(data["Restaurant"]),
      child: Container(
        margin: const EdgeInsets.only(bottom: 24, left: 12, right: 12),
        decoration: BoxDecoration(
          color: isInactive ? Colors.grey[300] : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 4),
            )
          ],
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
              child: Stack(
                children: [
                  SizedBox(
                    height: 140,
                    width: double.infinity,
                    child: (data["mediaList"] as List?)?.isNotEmpty ?? false
                        ? PageView.builder(
                            itemCount: data["mediaList"].length,
                            itemBuilder: (context, index) {
                              final url =
                                  data["mediaList"][index]; // ✅ No ["url"]
                              return Image.network(
                                url,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                loadingBuilder: (context, child, progress) =>
                                    progress == null
                                        ? child
                                        : const Center(
                                            child:
                                                CupertinoActivityIndicator()),
                                errorBuilder: (context, error, stackTrace) =>
                                    Image.asset(dish, fit: BoxFit.cover),
                              );
                            },
                          )
                        : Image.asset(
                            dish,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.2),
                            Colors.transparent
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    ),
                  ),
                  if (isInactive)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.45),
                        alignment: Alignment.center,
                        child: Text(
                          "Temporarily unavailable",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          data["Restaurant"],
                          style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: isInactive ? Colors.grey : Colors.black87,
                          ),
                        ),
                      ),
                      if (data["status"] != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(data["status"])
                                .withOpacity(0.15),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            data["status"],
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: _getStatusColor(data["status"]),
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Date, Items
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        data["date"] != null
                            ? DateFormat('MMM dd, yyyy').format(data["date"])
                            : data["time"] ?? "",
                        style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: isInactive ? Colors.grey : Colors.grey[700]),
                      ),
                      const Spacer(),
                      Text(
                        '${_capitalize(data["Items"])} ${int.tryParse(data["Items"].toString()) == 1 ? 'item' : 'items'}',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: isInactive ? Colors.grey : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      if (data["rating"] != null)
                        _buildRatingStars(data["rating"].toDouble()),
                      const Spacer(),
                      // Text(
                      //   '${data["itemPrice"] ?? data["price"]}',
                      //   style: GoogleFonts.poppins(
                      //     fontSize: 18,
                      //     fontWeight: FontWeight.bold,
                      //     color: AppColor.PrimaryColor,
                      //   ),
                      // ),
                    ],
                  ),

                  if (onReorder != null || onViewDetails != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Divider(thickness: 0.8, color: Colors.grey[200]),
                    ),

                  // Buttons
                  if (onReorder != null || onViewDetails != null)
                    Row(
                      children: [
                        if (onReorder != null)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: onReorder,
                              icon: const Icon(Icons.refresh,
                                  size: 18, color: Colors.black),
                              label: Text("Reorder",
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  )),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                side: BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                          ),
                        if (onReorder != null && onViewDetails != null)
                          const SizedBox(width: 12),
                        if (onViewDetails != null)
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: onViewDetails,
                              icon: const Icon(Icons.receipt_long,
                                  size: 18, color: Colors.white),
                              label: Text("Details",
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  )),
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                backgroundColor: AppColor.PrimaryColor,
                                elevation: 2,
                              ),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _capitalize(String input) {
  input = input.toLowerCase();
  if (input.isEmpty) return input;
  return input[0].toUpperCase() + input.substring(1);
}
