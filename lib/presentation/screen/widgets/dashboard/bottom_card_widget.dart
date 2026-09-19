import 'dart:ui';
import 'package:local_basket/core/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BottomCartCard extends StatelessWidget {
  final int itemCount;
  final double? totalPrice;
  final VoidCallback onTap;

  const BottomCartCard({
    super.key,
    required this.itemCount,
    required this.onTap,
    this.totalPrice,
  });

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final bool isNarrow = screenWidth < 360;
    final bool isWide = screenWidth >= 430;

    // Responsive spacing & typography that scale with the device width.
    final EdgeInsets margin = EdgeInsets.symmetric(
      horizontal: isNarrow ? 8 : (isWide ? 20 : 12),
      vertical: isNarrow ? 8 : 12,
    );
    final EdgeInsets contentPadding = EdgeInsets.symmetric(
      horizontal: isNarrow ? 12 : 16,
      vertical: isNarrow ? 10 : 8,
    );
    final double titleFontSize = isNarrow ? 13.5 : (isWide ? 16 : 15);
    final double subtitleFontSize = isNarrow ? 12 : 13.5;
    final double iconSize = isNarrow ? 20 : 22;

    return SafeArea(
      // Some devices (mainly certain Android OEM builds) under-report the
      // bottom system-nav inset, so this bar ends up hidden behind the
      // gesture/button bar. `minimum` guarantees a floor clearance while
      // still growing to match a larger real inset when the device reports one.
      minimum: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          margin: margin,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: Container(
                padding: contentPadding,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColor.PrimaryColor.withOpacity(0.95),
                      AppColor.PrimaryColor.withOpacity(0.9),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      color: Colors.white,
                      size: iconSize,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
                            style: GoogleFonts.poppins(
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (totalPrice != null)
                            Text(
                              '₹${totalPrice!.toStringAsFixed(2)}',
                              style: GoogleFonts.poppins(
                                fontSize: subtitleFontSize,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withOpacity(0.85),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isNarrow)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                      )
                    else
                      ElevatedButton.icon(
                        onPressed: onTap,
                        icon: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                        label: Text(
                          'View Cart',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: isWide ? 14 : 13,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.15),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(
                            horizontal: isWide ? 14 : 12,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
