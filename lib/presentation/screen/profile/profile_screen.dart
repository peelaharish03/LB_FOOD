import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/cupertino.dart';

import 'package:local_basket/components/custom_topbar.dart';
import 'package:local_basket/core/constants/colors.dart';
import 'package:local_basket/presentation/cubit/authentication/currentcustomer/get/current_customer_cubit.dart';
import 'package:local_basket/presentation/cubit/authentication/currentcustomer/get/current_customer_state.dart';
import 'package:local_basket/presentation/screen/address/address_screen.dart';
import 'package:local_basket/presentation/screen/order/myOrders_screen.dart';
import 'package:local_basket/presentation/screen/profile/faqs_screen.dart';
import 'package:local_basket/presentation/screen/profile/complaints_screen.dart';
import 'package:local_basket/presentation/screen/profile/offers_screen.dart';
import 'package:local_basket/presentation/screen/profile/pool_screen.dart';
import 'package:local_basket/presentation/screen/widgets/logout.dart';
import 'package:local_basket/presentation/screen/authentication/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _deleteRequested = false;

  @override
  void initState() {
    super.initState();
    context.read<CurrentCustomerCubit>().GetCurrentCustomer(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.White,
      appBar: CustomAppBar(title: "My Profile"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildUserProfile(context),
            const SizedBox(height: 24),
            _buildBasicOptions(context),
          ],
        ),
      ),
    );
  }

  //
  Widget _buildUserProfile(BuildContext context) {
    return BlocBuilder<CurrentCustomerCubit, CurrentCustomerState>(
      builder: (context, state) {
        if (state is CurrentCustomerLoaded) {
          final customer = state.currentCustomerModel;
          final fullName =
              [
                customer.firstName?.trim() ?? '',
                customer.lastName?.trim() ?? '',
              ].where((e) => e.isNotEmpty).join(' ');
          final hasName = fullName.isNotEmpty;
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: AppColor.PrimaryColor.withOpacity(0.1),
                  child: Icon(
                    Icons.person,
                    size: 40,
                    color: AppColor.PrimaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasName
                            ? fullName
                            : (customer.mobile ?? 'No Phone Number'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (hasName) ...[
                        const SizedBox(height: 6),
                        Text(
                          customer.mobile ?? 'No Phone Number',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        } else if (state is CurrentCustomerError) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.error, color: Colors.red),
              const SizedBox(height: 12),
              Text(state.message, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed:
                    () => context
                        .read<CurrentCustomerCubit>()
                        .GetCurrentCustomer(context),
                child: const Text("Retry"),
              ),
            ],
          );
        } else if (state is CurrentCustomerLoading) {
          return const Center(child: CupertinoActivityIndicator());
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildBasicOptions(BuildContext context) {
    final List<_Option> options = [
      _Option(
        Icons.shopping_bag_outlined,
        "My Orders",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => MyOrders()),
          );
        },
      ),
      _Option(
        Icons.local_offer_outlined,
        "Offers",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const OffersScreen()),
          );
        },
      ),
      _Option(
        Icons.emoji_events_outlined,
        "Pool",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PoolScreen()),
          );
        },
      ),
      _Option(
        Icons.location_on_outlined,
        "Saved Addresses",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddressScreen()),
          );
        },
      ),
      _Option(
        Icons.report_problem_outlined,
        "Complaints",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ComplaintsScreen()),
          );
        },
      ),
      _Option(
        Icons.help_outline,
        "FAQs",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FaqsScreen()),
          );
        },
      ),
      _Option(
        Icons.logout,
        "Logout",
        onTap: () {
          showModalBottomSheet(
            context: context,
            builder: (_) => const LogOutCnfrmBottomSheet(),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
          );
        },
      ),
      _Option(
        Icons.delete_forever_outlined,
        "Delete Account",
        onTap:
            _deleteRequested
                ? null
                : () => _showDeleteConfirmationDialog(context),
      ),
    ];

    return Column(
      children:
          options.map((opt) {
            final bool isDisabled = opt.onTap == null;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.08),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                leading: Icon(
                  opt.icon,
                  color:
                      isDisabled
                          ? Colors.grey
                          : (opt.isDestructive
                              ? Colors.red
                              : AppColor.PrimaryColor),
                ),
                title: Text(
                  opt.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    color:
                        isDisabled
                            ? Colors.grey
                            : (opt.isDestructive ? Colors.red : Colors.black),
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color:
                      isDisabled
                          ? Colors.grey.shade300
                          : (opt.isDestructive ? Colors.red : Colors.grey),
                ),
                onTap: opt.onTap,
              ),
            );
          }).toList(),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColor.PrimaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.delete_forever_rounded,
                      color: AppColor.PrimaryColor,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    "Delete Account",
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Are you sure you want to delete this account? This action cannot be undone.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.5,
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 26),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(dialogContext);
                            setState(() => _deleteRequested = true);
                            await _showAutoDismissDialog(
                              context,
                              "Your account is going to be deleted within 24 hours.",
                            );
                            if (!context.mounted) return;
                            SharedPreferences prefs =
                                await SharedPreferences.getInstance();
                            await prefs.clear();
                            if (!context.mounted) return;
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                              (route) => false,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColor.PrimaryColor,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            "Yes, Delete",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColor.White,
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

  Future<void> _showAutoDismissDialog(BuildContext context, String message) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _AutoDismissDialog(message: message),
    );
  }
}

class _AutoDismissDialog extends StatelessWidget {
  final String message;

  const _AutoDismissDialog({required this.message});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Colors.green,
                size: 40,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              "Account Deletion Scheduled",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.5,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 22),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(seconds: 5),
              onEnd: () => Navigator.of(context).maybePop(),
              builder:
                  (context, value, _) => ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: value,
                      minHeight: 5,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColor.PrimaryColor,
                      ),
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Option {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  _Option(this.icon, this.title, {this.onTap});

  bool get isDestructive =>
      title.toLowerCase().contains("logout") ||
      title.toLowerCase().contains("delete");
}
