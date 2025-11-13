import 'package:flutter/material.dart';
import 'package:local_basket/core/constants/colors.dart';
import 'package:local_basket/components/custom_topbar.dart';

class FaqsScreen extends StatelessWidget {
  const FaqsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final faqs = <Map<String, String>>[
      {
        'q': 'How do I track my order?',
        'a': 'Go to My Orders in Profile and select an order to see its status.'
      },
      {
        'q': 'How can I reorder items?',
        'a': 'Open a past order in My Orders and use the Reorder option if available.'
      },
      {
        'q': 'How do I add or edit my address?',
        'a': 'Go to Saved Addresses in Profile to add, edit, or remove addresses.'
      },
      {
        'q': 'How do I contact support?',
        'a': 'Use the help option in the app or email our support listed on the website.'
      },
    ];

    return Scaffold(
      backgroundColor: AppColor.White,
      appBar: const CustomAppBar(title: 'FAQs'),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: faqs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = faqs[index];
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                title: Text(
                  item['q'] ?? '',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      item['a'] ?? '',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
