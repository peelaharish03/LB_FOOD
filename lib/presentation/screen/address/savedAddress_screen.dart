import 'package:local_basket/core/constants/colors.dart';
import 'package:local_basket/core/utils/address_formatter.dart';
import 'package:local_basket/data/model/address/getAddress/getAddress_model.dart';
import 'package:local_basket/presentation/cubit/address/defaultAddress/get/getDefaultAddress_cubit.dart';
import 'package:local_basket/presentation/cubit/address/defaultAddress/post/defaultAddress_cubit.dart';
import 'package:local_basket/presentation/cubit/address/deleteAddress/deleteAddress_cubit.dart';
import 'package:local_basket/presentation/cubit/address/getAddress/getAddress_cubit.dart';
import 'package:local_basket/presentation/cubit/address/getAddress/getAddress_state.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SavedAddressesView extends StatefulWidget {
  final Function(Content)? onAddressSelected;
  final Function(Content)? onEditAddress;
  final VoidCallback? onAddNewAddressTap;

  /// When true (cart flow) tapping a card selects the address and pops back
  /// with the result. When false (profile flow) tapping a card just marks it
  /// as the default and stays on the screen.
  final bool selectionMode;

  const SavedAddressesView({
    super.key,
    this.onAddressSelected,
    this.onEditAddress,
    this.onAddNewAddressTap,
    this.selectionMode = false,
  });

  @override
  State<SavedAddressesView> createState() => _SavedAddressesViewState();
}

class _SavedAddressesViewState extends State<SavedAddressesView> {
  // Id of the address the user has tapped as their default in this session.
  String? _selectedAddressId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GetAddressCubit, GetAddressState>(
      builder: (context, state) {
        if (state is GetAddressLoading) {
          return Center(
            child: CupertinoActivityIndicator(color: AppColor.PrimaryColor),
          );
        }

        if (state is GetAddressSuccess) {
          return _buildAddressList(context, state.addressModel.content);
        }

        if (state is GetAddressFailure) {
          return _buildErrorView(context, state);
        }

        return Center(
          child: CupertinoActivityIndicator(color: AppColor.PrimaryColor),
        );
      },
    );
  }

  Widget _buildAddressList(BuildContext context, List<Content> addresses) {
    if (addresses.isEmpty) {
      return _buildEmptyView(context);
    }

    return RefreshIndicator(
      color: AppColor.PrimaryColor,
      onRefresh:
          () async => context.read<GetAddressCubit>().fetchAddress(context),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: addresses.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final address = addresses[index];
          final isSelected = _selectedAddressId != null &&
              _selectedAddressId == address.id;
          return _buildAddressCard(context, address, isSelected: isSelected);
        },
      ),
    );
  }

  Widget _buildEmptyView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColor.PrimaryColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_off_outlined,
                size: 40,
                color: AppColor.PrimaryColor,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              "No saved addresses yet",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              "Add an address to get your orders delivered faster.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: widget.onAddNewAddressTap,
              icon: const Icon(Icons.add, size: 18),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.PrimaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              label: const Text("Add New Address"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, GetAddressFailure state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              state.error.isEmpty ? "Failed to load addresses" : state.error,
              style: TextStyle(fontSize: 15, color: Colors.red.shade700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed:
                  () => context.read<GetAddressCubit>().fetchAddress(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.PrimaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text("Retry"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard(
    BuildContext context,
    Content address, {
    bool isSelected = false,
  }) {
    final item = address.address;
    final addressString = _formatAddress(address);
    final type = (item?.addressType ?? '').trim();
    final name = (item?.name ?? address.userName ?? '').trim();
    final phone = (item?.mobileNumber ?? '').trim();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppColor.PrimaryColor : Colors.grey.shade200,
          width: isSelected ? 1.6 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _handleCardTap(context, address, addressString),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: AppColor.PrimaryColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _iconForType(type),
                        color: AppColor.PrimaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name.isEmpty ? "Address" : name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (type.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              _titleCase(type),
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (isSelected) _pill("DEFAULT"),
                  ],
                ),
                if (addressString.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    addressString,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.45,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
                if (phone.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.call_outlined,
                          size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 6),
                      Text(
                        phone,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Divider(height: 1, color: Colors.grey.shade200),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (widget.selectionMode)
                      Text(
                        "Tap to deliver here",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      )
                    else
                      Text(
                        isSelected ? "Default address" : "Tap to set default",
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected
                              ? AppColor.PrimaryColor
                              : Colors.grey.shade500,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    const Spacer(),
                    _iconAction(
                      icon: Icons.edit_outlined,
                      color: AppColor.PrimaryColor,
                      tooltip: "Edit",
                      onTap: () {
                        final addressId = address.id;
                        if (addressId == null || addressId.isEmpty) return;
                        widget.onEditAddress?.call(address);
                      },
                    ),
                    const SizedBox(width: 6),
                    _iconAction(
                      icon: Icons.delete_outline,
                      color: Colors.red.shade400,
                      tooltip: "Delete",
                      onTap: () {
                        final addressId = address.id;
                        if (addressId == null || addressId.isEmpty) return;
                        _showDeleteConfirmation(context, addressId);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Logic unchanged — only the branch that used to pop for the profile flow
  // now stays on screen and refreshes the highlighted default instead.
  void _handleCardTap(
    BuildContext context,
    Content address,
    String addressString,
  ) {
    if (widget.onAddressSelected != null) {
      widget.onAddressSelected!(address);
      return;
    }

    final addressId = address.id;
    if (addressId == null || addressId.isEmpty) return;

    context.read<DefaultAddressCubit>().setDefaultAddress(addressId, context);
    context.read<AddressSavetoCartCubit>().addressSavetoCart(addressId, context);

    if (widget.selectionMode) {
      Navigator.pop(context, {
        'address': addressString,
        'addressId': addressId,
      });
    } else {
      setState(() => _selectedAddressId = addressId);
    }
  }

  Widget _pill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColor.PrimaryColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _iconAction({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type.toLowerCase()) {
      case 'home':
        return Icons.home_outlined;
      case 'work':
      case 'office':
        return Icons.work_outline;
      default:
        return Icons.location_on_outlined;
    }
  }

  String _titleCase(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }

  String _formatAddress(Content address) {
    final item = address.address;
    if (item == null) return '';
    return joinAddressParts([
      item.line1,
      item.line2,
      item.fullText,
      item.city,
      item.state,
      item.country,
      item.postalCode,
    ]);
  }

  // Logic unchanged: still pops the dialog then fires DeleteAddressCubit.
  void _showDeleteConfirmation(BuildContext context, String addressId) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.delete_outline,
                    color: Colors.red.shade400, size: 30),
              ),
              const SizedBox(height: 18),
              const Text(
                "Delete Address",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                "Are you sure you want to delete this address? This action can't be undone.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.45,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        "Cancel",
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        context.read<DeleteAddressCubit>().deleteAddress(
                              addressId,
                              context,
                            );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade400,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text("Delete"),
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
