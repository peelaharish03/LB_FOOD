import 'package:local_basket/core/constants/colors.dart';
import 'package:local_basket/core/constants/img_const.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FoodCategoryIcons extends StatefulWidget {
  final void Function(String) onCategoryTap;

  const FoodCategoryIcons({super.key, required this.onCategoryTap});

  @override
  State<FoodCategoryIcons> createState() => _FoodCategoryIconsState();
}

class _FoodCategoryIconsState extends State<FoodCategoryIcons> {
  String? selectedLabel;

  List<Map<String, dynamic>> categories = [
    {"image": biriyani, "label": "Biriyani"},
    {"image": sandwich, "label": "Sandwich"},
    {"image": rolls, "label": "Rolls"},
    {"image": pizza, "label": "Pizza"},
    {"image": dessert, "label": "Dessert"},
  ];

  void _handleTap(String label) {
    setState(() {
      if (selectedLabel == label) {
        selectedLabel = null;
      } else {
        selectedLabel = label;

        final tapped = categories.firstWhere((cat) => cat['label'] == label);
        categories.removeWhere((cat) => cat['label'] == label);
        categories.insert(0, tapped);
      }
    });

    widget.onCategoryTap(selectedLabel ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 18),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = selectedLabel == category["label"];

          return GestureDetector(
            onTap: () => _handleTap(category["label"]),
            child: Column(
              children: [
                Stack(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color:
                              isSelected ? AppColor.White : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : [],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          category["image"],
                          width: 58,
                          height: 58,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: AppColor.White,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.black,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  category["label"],
                  style: GoogleFonts.poppins(
                    color: isSelected ? AppColor.White : Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
