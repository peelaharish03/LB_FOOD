import 'package:flutter/material.dart';
import 'package:upgrader/upgrader.dart';
import 'package:local_basket/presentation/screen/widgets/dashboard/app_update_dialog.dart';

/// Compares the installed app version against the version published on the
/// Play Store / App Store and, if a newer version exists, prompts the user
/// to update. Dismissible ("Later") — does not block app usage.
Future<void> checkForAppUpdate(BuildContext context) async {
  final upgrader = Upgrader.sharedInstance;

  try {
    await upgrader.initialize();
  } catch (e) {
    debugPrint('App update check failed: $e');
    return;
  }

  if (!context.mounted) return;
  if (!upgrader.isUpdateAvailable()) return;

  await AppUpdateDialog.show(
    context,
    currentVersion: upgrader.currentInstalledVersion,
    latestVersion: upgrader.currentAppStoreVersion,
    onUpdate: () => upgrader.sendUserToAppStore(),
    onLater: () {},
  );
}
