import 'package:local_basket/components/custom_snackbar.dart';
import 'package:local_basket/components/custom_topbar.dart';
import 'package:local_basket/core/constants/colors.dart';
import 'package:local_basket/data/model/address/getAddress/getAddress_model.dart';
import 'package:local_basket/presentation/cubit/address/deleteAddress/deleteAddress_cubit.dart';
import 'package:local_basket/presentation/cubit/address/deleteAddress/deleteAddress_state.dart';
import 'package:local_basket/presentation/cubit/address/saveAddress/saveAddress_cubit.dart';
import 'package:local_basket/presentation/cubit/address/saveAddress/saveAddress_state.dart';
import 'package:local_basket/presentation/cubit/address/getAddress/getAddress_cubit.dart';
import 'package:local_basket/presentation/screen/address/savedAddress_screen.dart';
import 'package:local_basket/presentation/screen/widgets/dashboard/geo_location_picker_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';

class AddressScreen extends StatefulWidget {
  final Function(Content)? selectedAddress;

  const AddressScreen({super.key, this.selectedAddress});
  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final houseController = TextEditingController();
  final streetController = TextEditingController();
  final landmarkController = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  final pincodeController = TextEditingController();
  final countryController = TextEditingController();
  LatLng? _selectedLatLng;
  bool _isLocationPicked = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchAddresses();
  }

  @override
  void dispose() {
    _tabController.dispose();
    nameController.dispose();
    phoneController.dispose();
    houseController.dispose();
    streetController.dispose();
    landmarkController.dispose();
    cityController.dispose();
    stateController.dispose();
    pincodeController.dispose();
    countryController.dispose();
    super.dispose();
  }

  void _fetchAddresses() =>
      context.read<GetAddressCubit>().fetchAddress(context);

  void _saveAddress() {
    if (!_formKey.currentState!.validate() || !_isLocationPicked) {
      if (!_isLocationPicked) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please pick a location")),
        );
      }
      return;
    }
    final payload = {
    "addressLine1": houseController.text.trim() + landmarkController.text.trim() + streetController.text.trim(),
    "cityId": "629ea4fa-d5a8-4226-8f73-9af84e47ed83",
    "stateId": "b202962e-e7ee-43e5-adce-4de972c4f3ba",
    "country": "IN",
    "postalCode": pincodeController.text.trim()
};
    // {
    //   "addressLine1": houseController.text.trim(),
    //   "addressLine2": landmarkController.text.trim(),
    //   "street": streetController.text.trim(),
    //   "city": cityController.text.trim(),
    //   "state": stateController.text.trim(),
    //   "country": countryController.text.trim(),
    //   "latitude": _selectedLatLng?.latitude ?? 0.0,
    //   "longitude": _selectedLatLng?.longitude ?? 0.0,
    //   "postalCode": pincodeController.text.trim(),
    //   "name": nameController.text.trim(),
    //   "phone": phoneController.text.trim(),
    // };
    context.read<SaveAddressCubit>().saveAddress(payload, context);
  }

  void _fillAddressFields(Placemark placemark, LatLng? latLng) {
    setState(() {
      streetController.text = [placemark.street, placemark.thoroughfare]
          .where((p) => p != null && p.isNotEmpty)
          .join(', ');
      cityController.text = placemark.locality ?? placemark.subLocality ?? '';
      stateController.text = placemark.administrativeArea ?? '';
      pincodeController.text = placemark.postalCode ?? '';
      countryController.text = placemark.country ?? '';
      houseController.text = [placemark.name, placemark.subThoroughfare]
          .where((p) => p != null && p.isNotEmpty)
          .join(', ');
      _selectedLatLng = latLng;
      _isLocationPicked = true;
    });
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerPage(
          onLocationSelected: (latLng, placemark) =>
              _fillAddressFields(placemark, latLng),
        ),
      ),
    );

    if (result == true) {
      CustomSnackbars.showSuccessSnack(
        context: context,
        title: "Success",
        message: "Location selected successfully",
      );
    } else {
      CustomSnackbars.showErrorSnack(
        context: context,
        title: "Al ",
        message: "Failed to select location",
      );
    }
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
    bool required = true,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              if (required)
                const Text(
                  '*',
                  style: TextStyle(color: Colors.red),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            validator: validator,
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: Colors.grey.shade400,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: Colors.grey.shade400,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: AppColor.PrimaryColor,
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: Colors.red,
                ),
              ),
              hintText: 'Enter $label',
              hintStyle: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
              ),
            ),
            style: const TextStyle(
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    setState(() {
      _selectedLatLng = null;
      _isLocationPicked = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (scaffoldContext) {
      return Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(200),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomAppBar(
                title: "Manage Addresses",
                showBackButton: true,
                onBackPressed: () {
                  Navigator.pop(context);
                  _clearForm();
                },
              ),
              TabBar(
                controller: _tabController,
                labelColor: AppColor.PrimaryColor,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppColor.PrimaryColor,
                tabs: const [
                  Tab(text: "Saved Addresses"),
                  Tab(text: "Add New Address"),
                ],
              ),
            ],
          ),
        ),
        backgroundColor: AppColor.White,
        body: MultiBlocListener(
          listeners: [
            BlocListener<SaveAddressCubit, SaveAddressState>(
              listener: (context, state) {
                if (state is SaveAddressSuccess) {
                  CustomSnackbars.showSuccessSnack(
                    context: scaffoldContext,
                    title: "Success",
                    message: "Address Saved Successfully",
                  );
                  _clearForm();
                  _fetchAddresses();
                  _tabController.animateTo(0);
                } else if (state is SaveAddressFailure) {
                  CustomSnackbars.showErrorSnack(
                    context: scaffoldContext,
                    title: "Failed",
                    message: "Failed to Save Address",
                  );
                }
              },
            ),
            BlocListener<DeleteAddressCubit, DeleteAddressState>(
              listener: (context, state) {
                if (state is DeleteAddressSuccess) {
                  CustomSnackbars.showSuccessSnack(
                    context: scaffoldContext,
                    title: "Success",
                    message: "Address Deleted Successfully",
                  );
                  _fetchAddresses();
                } else if (state is DeleteAddressFailure) {
                  CustomSnackbars.showErrorSnack(
                    context: scaffoldContext,
                    title: "Failed",
                    message: "Failed to Delete Address",
                  );
                }
              },
            ),
          ],
          child: TabBarView(
            controller: _tabController,
            children: [
              SavedAddressesView(
                onAddNewAddressTap: () {
                  _tabController.animateTo(1);
                },
              ),
              SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Add New Address",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        label: "Full Name",
                        controller: nameController,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Please enter your name'
                            : null,
                      ),
                      _buildTextField(
                        label: "Phone Number",
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Please enter phone number';
                          }
                          if (v.trim().length != 10) {
                            return 'Please enter a valid 10-digit phone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Location *",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _pickLocation,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _isLocationPicked
                                  ? AppColor.PrimaryColor
                                  : Colors.grey.shade400,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                color: _isLocationPicked
                                    ? AppColor.PrimaryColor
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _isLocationPicked
                                      ? "Location selected"
                                      : "Pick location from map",
                                  style: TextStyle(
                                    color: _isLocationPicked
                                        ? Colors.green
                                        : Colors.grey.shade600,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: Colors.grey.shade500,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        label: "House No. / Building",
                        controller: houseController,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Please enter house/building details'
                            : null,
                      ),
                      _buildTextField(
                        label: "Street / Locality",
                        controller: streetController,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Please enter street/locality'
                            : null,
                      ),
                      _buildTextField(
                        label: "Landmark (optional)",
                        controller: landmarkController,
                        required: false,
                      ),
                      _buildTextField(
                        label: "City",
                        controller: cityController,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Please enter city'
                            : null,
                      ),
                      _buildTextField(
                        label: "State",
                        controller: stateController,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Please enter state'
                            : null,
                      ),
                      _buildTextField(
                        label: "Pincode",
                        controller: pincodeController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Please enter pincode';
                          }
                          if (v.trim().length != 6) {
                            return 'Please enter a valid 6-digit pincode';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      BlocBuilder<SaveAddressCubit, SaveAddressState>(
                        builder: (context, state) => SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: state is SaveAddressLoading
                                ? null
                                : _saveAddress,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColor.PrimaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: state is SaveAddressLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CupertinoActivityIndicator(
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    "Save Address",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
