import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_basket/core/constants/colors.dart';

class AppUpdateDialog extends StatelessWidget {
  final String? currentVersion;
  final String? latestVersion;
  final VoidCallback onUpdate;
  final VoidCallback? onLater;

  const AppUpdateDialog({
    super.key,
    this.currentVersion,
    this.latestVersion,
    required this.onUpdate,
    this.onLater,
  });

  static Future<void> show(
    BuildContext context, {
    String? currentVersion,
    String? latestVersion,
    required VoidCallback onUpdate,
    VoidCallback? onLater,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AppUpdateDialog(
            currentVersion: currentVersion,
            latestVersion: latestVersion,
            onUpdate: onUpdate,
            onLater: onLater,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.system_update_rounded,
                size: 48,
                color: AppColor.PrimaryColor,
              ),
              const SizedBox(height: 16),
              Text(
                "Update Available",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                latestVersion != null
                    ? "A new version ($latestVersion) of Localbasket is available. Update now for the latest features and fixes."
                    : "A new version of Localbasket is available. Update now for the latest features and fixes.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  if (onLater != null)
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          onLater?.call();
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          foregroundColor: Colors.black87,
                        ),
                        child: Text(
                          "Later",
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  if (onLater != null) const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onUpdate();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.PrimaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        "Update Now",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
