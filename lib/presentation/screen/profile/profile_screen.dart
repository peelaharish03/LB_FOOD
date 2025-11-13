import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/cupertino.dart';

import 'package:local_basket/components/custom_snackbar.dart';
import 'package:local_basket/components/custom_topbar.dart';
import 'package:local_basket/core/constants/colors.dart';
import 'package:local_basket/presentation/cubit/authentication/currentcustomer/get/current_customer_cubit.dart';
import 'package:local_basket/presentation/cubit/authentication/currentcustomer/get/current_customer_state.dart';
import 'package:local_basket/presentation/cubit/authentication/deleteAccount/deleteAccount_cubit.dart';
import 'package:local_basket/presentation/cubit/authentication/deleteAccount/deleteAccount_state.dart';
import 'package:local_basket/presentation/screen/address/address_screen.dart';
import 'package:local_basket/presentation/screen/order/myOrders_screen.dart';
import 'package:local_basket/presentation/screen/profile/faqs_screen.dart';
import 'package:local_basket/presentation/screen/profile/complaints_screen.dart';
import 'package:local_basket/presentation/screen/widgets/logout.dart';
import 'package:local_basket/presentation/screen/authentication/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final bool isGuest;
  const ProfileScreen({super.key, this.isGuest = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    context.read<CurrentCustomerCubit>().GetCurrentCustomer(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.White,
      appBar: CustomAppBar(
        title: "My Profile",
      ),
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

  Widget _buildUserProfile(BuildContext context) {
    return BlocBuilder<CurrentCustomerCubit, CurrentCustomerState>(
      builder: (context, state) {
        if (state is CurrentCustomerLoaded) {
          final customer = state.currentCustomerModel;
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
                  child: Icon(Icons.person,
                      size: 40, color: AppColor.PrimaryColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.fullName ?? 'No Name',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        customer.primaryContact ?? 'No Phone Number',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
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
                onPressed: () => context
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
      _Option(Icons.shopping_bag_outlined, "My Orders", onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => MyOrders()));
      }),
      _Option(Icons.location_on_outlined, "Saved Addresses", onTap: () {
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => AddressScreen()));
      }),
      _Option(Icons.report_problem_outlined, "Complaints", onTap: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ComplaintsScreen()));
      }),
      _Option(Icons.help_outline, "FAQs", onTap: () {
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const FaqsScreen()));
      }),
      _Option(Icons.logout, "Logout", onTap: () {
        showModalBottomSheet(
          context: context,
          builder: (_) => const LogOutCnfrmBottomSheet(),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
        );
      }),
      _Option(Icons.delete_forever_outlined, "Delete Account", onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useRootNavigator: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (_) => _buildDeleteConfirmation(context),
        );
      }),
    ];

    return Column(
      children: options.map((opt) {
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
            contentPadding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            leading: Icon(opt.icon,
                color: opt.isDestructive ? Colors.red : AppColor.PrimaryColor),
            title: Text(
              opt.title,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16,
                color: opt.isDestructive ? Colors.red : Colors.black,
              ),
            ),
            trailing: Icon(Icons.chevron_right,
                color: opt.isDestructive ? Colors.red : Colors.grey),
            onTap: opt.onTap,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDeleteConfirmation(BuildContext context) {
    return BlocProvider.value(
      value: context.read<DeleteAccountCubit>(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber_rounded,
                color: AppColor.PrimaryColor, size: 48),
            const SizedBox(height: 16),
            Text("Are you sure?",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColor.PrimaryColor)),
            const SizedBox(height: 12),
            const Text(
              "This will permanently delete your account and all associated data.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: BlocConsumer<DeleteAccountCubit, DeleteAccountState>(
                    listener: (context, state) async {
                      if (state is DeleteAccountSuccess) {
                        Navigator.pop(context);
                        CustomSnackbars.showSuccessSnack(
                          context: context,
                          title: "Deleted",
                          message: "Your account has been deleted.",
                        );
                        SharedPreferences prefs =
                            await SharedPreferences.getInstance();
                        prefs.clear();
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                              builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      } else if (state is DeleteAccountFailure) {
                        CustomSnackbars.showErrorSnack(
                          context: context,
                          title: "Error",
                          message: "Failed to delete account",
                        );
                      }
                    },
                    builder: (context, state) {
                      return ElevatedButton(
                        onPressed: state is DeleteAccountLoading
                            ? null
                            : () {
                                context
                                    .read<DeleteAccountCubit>()
                                    .deleteAccount();
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                        ),
                        child: state is DeleteAccountLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text("Delete"),
                      );
                    },
                  ),
                ),
              ],
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
