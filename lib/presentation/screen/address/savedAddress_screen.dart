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

class SavedAddressesView extends StatelessWidget {
  final Function(Content)? onAddressSelected;
  final VoidCallback? onAddNewAddressTap;

  const SavedAddressesView({
    super.key,
    this.onAddressSelected,
    this.onAddNewAddressTap,
  });

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
          final addresses = state.addressModel.content;
          return _buildAddressList(context, addresses);
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
    final sortedAddresses = List<Content>.from(addresses);

    if (sortedAddresses.isEmpty) {
      return _buildEmptyView(context);
    }

    return RefreshIndicator(
      onRefresh:
          () async => context.read<GetAddressCubit>().fetchAddress(context),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sortedAddresses.length,
        itemBuilder:
            (context, index) => _buildAddressCard(
              context,
              sortedAddresses[index],
              isDefault: sortedAddresses[index].isDefault ?? false,
            ),
      ),
    );
  }

  Widget _buildEmptyView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            "No saved addresses yet",
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onAddNewAddressTap,
            child: Text(
              "Add New Address",
              style: TextStyle(color: AppColor.PrimaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, GetAddressFailure state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
          const SizedBox(height: 16),
          Text(
            "Failed to load addresses",
            style: TextStyle(fontSize: 16, color: Colors.red.shade700),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed:
                () => context.read<GetAddressCubit>().fetchAddress(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.PrimaryColor,
            ),
            child: const Text(
              "Retry",
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(
    BuildContext context,
    Content address, {
    bool isDefault = false,
  }) {
    final addressString = _formatAddress(address);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDefault ? AppColor.PrimaryColor : Colors.grey.shade200,
          width: isDefault ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (onAddressSelected != null) {
            onAddressSelected!(address);
          } else {
            final addressId = address.id;
            if (addressId == null || addressId.isEmpty) return;
            context.read<DefaultAddressCubit>().setDefaultAddress(
              addressId,
              context,
            );
            context.read<AddressSavetoCartCubit>().addressSavetoCart(
              addressId,
              context,
            );
            Navigator.pop(context, addressString);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: AppColor.PrimaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isDefault ? "Default Address" : "Saved Address",
                    style: TextStyle(
                      color:
                          isDefault
                              ? AppColor.PrimaryColor
                              : Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (isDefault) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.check_circle,
                      color: AppColor.PrimaryColor,
                      size: 18,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              if (addressString.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    addressString,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    icon: Icon(Icons.delete, size: 18, color: Colors.red),
                    label: const Text(
                      "DELETE",
                      style: TextStyle(color: Colors.red),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      side: BorderSide(
                        color: Colors.red.withValues(alpha: 0.5),
                      ),
                    ),
                    onPressed: () {
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
    );
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

  void _showDeleteConfirmation(BuildContext context, String addressId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Delete Address"),
            content: const Text(
              "Are you sure you want to delete this address?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("CANCEL"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.read<DeleteAddressCubit>().deleteAddress(
                    addressId,
                    context,
                  );
                },
                child: const Text(
                  "DELETE",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }
}
