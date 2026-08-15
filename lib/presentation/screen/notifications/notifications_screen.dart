import 'package:flutter/material.dart';
import 'package:local_basket/components/custom_topbar.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(
        title: 'Notifications',
        showBackButton: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 120),
          child: Column(
            children: [
              Icon(Icons.notifications_none_rounded,
                  size: 80, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text(
                "No notifications yet",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
