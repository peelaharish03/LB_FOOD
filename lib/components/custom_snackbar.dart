import 'dart:async';
import 'package:flutter/material.dart';

class CustomSnackbars {
  static void showSuccessSnack({
    required BuildContext context,
    required String title,
    required String message,
    Duration? duration,
  }) {
    _showOverlaySnackbar(
      context: context,
      title: title,
      message: message,
      icon: Icons.check_circle,
      backgroundColor: const Color(0xFFDCFCE7),
      iconColor: const Color(0xFF22C55E),
      textColor: const Color(0xFF166534),
      duration: duration,
    );
  }

  static void showErrorSnack({
    required BuildContext context,
    required String title,
    required String message,
  }) {
    _showOverlaySnackbar(
      context: context,
      title: title,
      message: message,
      icon: Icons.error,
      backgroundColor: const Color(0xFFFEE2E2),
      iconColor: const Color(0xFFDC2626),
      textColor: const Color(0xFF7F1D1D),
    );
  }

  static void showInfoSnack({
    required BuildContext context,
    required String title,
    required String message,
  }) {
    _showOverlaySnackbar(
      context: context,
      title: title,
      message: message,
      icon: Icons.info,
      backgroundColor: const Color(0xFFE0F2FE),
      iconColor: const Color(0xFF0284C7),
      textColor: const Color(0xFF075985),
    );
  }

  static void _showOverlaySnackbar({
    required BuildContext context,
    required String title,
    required String message,
    required IconData icon,
    required Color backgroundColor,
    required Color iconColor,
    required Color textColor,
    Duration? duration,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    final animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: Navigator.of(context),
    );

    final animation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: animationController, curve: Curves.easeOut));

    final double topPadding = MediaQuery.of(context).padding.top + 8;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: topPadding,
        left: 20,
        right: 20,
        child: SlideTransition(
          position: animation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(icon, color: iconColor, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          message,
                          style: TextStyle(
                            fontSize: 13,
                            color: textColor.withOpacity(0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    animationController.forward();

    Timer(duration ?? const Duration(seconds: 3), () async {
      await animationController.reverse();
      overlayEntry.remove();
      animationController.dispose();
    });
  }
}
