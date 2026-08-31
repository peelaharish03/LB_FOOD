import 'package:local_basket/components/custom_snackbar.dart';
import 'package:local_basket/components/custom_topbar.dart';
import 'package:local_basket/core/constants/colors.dart';
import 'package:local_basket/core/utils/address_formatter.dart';
import 'package:local_basket/core/utils/location_validator.dart';
import 'package:local_basket/data/model/address/getAddress/getAddress_model.dart';
import 'package:local_basket/data/model/address/state/state_model.dart';
import 'package:local_basket/presentation/cubit/address/city/getCities_cubit.dart';
import 'package:local_basket/presentation/cubit/address/city/getCities_state.dart';
import 'package:local_basket/presentation/cubit/address/deleteAddress/deleteAddress_cubit.dart';
import 'package:local_basket/presentation/cubit/address/deleteAddress/deleteAddress_state.dart';
import 'package:local_basket/presentation/cubit/address/saveAddress/saveAddress_cubit.dart';
import 'package:local_basket/presentation/cubit/address/saveAddress/saveAddress_state.dart';
import 'package:local_basket/presentation/cubit/address/getAddress/getAddress_cubit.dart';
import 'package:local_basket/presentation/cubit/address/state/getStates_cubit.dart';
import 'package:local_basket/presentation/cubit/address/state/getStates_state.dart';
import 'package:local_basket/presentation/cubit/authentication/currentcustomer/get/current_customer_cubit.dart';
import 'package:local_basket/presentation/cubit/authentication/currentcustomer/get/current_customer_state.dart';
import 'package:local_basket/presentation/screen/address/savedAddress_screen.dart';
import 'package:local_basket/presentation/screen/widgets/dashboard/geo_location_picker_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

  // Serviceable states/cities as returned by the states/cities APIs. State
  // and City are shown as read-only fields defaulted to the (currently
  // single) serviceable state/city; the stateId/cityId sent to the
  // save-address API are resolved by matching that text against these lists.
  List<StateModel> _states = [];
  List<CityModel> _allCities = [];

  // Delivery location picked on the map. Required to save an address —
  // also used to reject addresses outside the serviceable radius.
  LatLng? _selectedLatLng;
  bool _isLocationPicked = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchAddresses();
    _fetchStates();
    _fetchAllCities();
    _fetchCurrentCustomer();
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
    super.dispose();
  }

  void _fetchAddresses() =>
      context.read<GetAddressCubit>().fetchAddress(context);

  void _fetchStates() => context.read<GetStatesCubit>().getStates(context);

  void _fetchAllCities() => context.read<GetCitiesCubit>().getCities(context);

  void _fetchCurrentCustomer() =>
      context.read<CurrentCustomerCubit>().GetCurrentCustomer(context);

  String _normalizePhoneNumber(String? raw) {
    final digits = (raw ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.length <= 10) return digits;
    return digits.substring(digits.length - 10);
  }

  StateModel? _matchState(String stateText) {
    final key = looseMatchKey(stateText);
    if (key.isEmpty) return null;
    for (final state in _states) {
      if (looseMatchKey(state.name) == key) return state;
    }
    return null;
  }

  CityModel? _matchCity(String cityText, StateModel state) {
    final key = looseMatchKey(cityText);
    if (key.isEmpty) return null;
    final stateCode = state.code?.toLowerCase();
    for (final city in _allCities) {
      if (looseMatchKey(city.name) == key &&
          city.stateCode?.toLowerCase() == stateCode) {
        return city;
      }
    }
    return null;
  }

  // Defaults State/City to the first serviceable entries returned by the
  // states/cities APIs, since there is currently only one serviceable
  // state/city and there is no map picker anymore to derive them from.
  void _applyDefaultLocation() {
    if (_states.isEmpty) return;

    StateModel? defaultState;
    if (stateController.text.trim().isEmpty) {
      defaultState = _states.first;
      setState(() {
        stateController.text = defaultState!.name;
      });
    } else {
      defaultState = _matchState(stateController.text.trim());
    }

    if (defaultState == null || _allCities.isEmpty) return;
    if (cityController.text.trim().isEmpty) {
      final stateCode = defaultState.code?.toLowerCase();
      final candidates =
          _allCities.where((c) => c.stateCode?.toLowerCase() == stateCode);
      final defaultCity =
          candidates.isNotEmpty ? candidates.first : _allCities.first;
      setState(() {
        cityController.text = defaultCity.name;
      });
    }
  }

  void _applyDefaultPhone() {
    if (phoneController.text.trim().isNotEmpty) return;
    final customerState = context.read<CurrentCustomerCubit>().state;
    if (customerState is CurrentCustomerLoaded) {
      final mobile = _normalizePhoneNumber(
        customerState.currentCustomerModel.mobile,
      );
      if (mobile.isNotEmpty) {
        setState(() {
          phoneController.text = mobile;
        });
      }
    }
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => LocationPickerPage(
              onLocationSelected: (latLng, placemark) {
                setState(() {
                  _selectedLatLng = latLng;
                  _isLocationPicked = true;
                });
              },
            ),
      ),
    );

    if (result == true) {
      CustomSnackbars.showSuccessSnack(
        context: context,
        title: "Success",
        message: "Location selected successfully",
      );
    }
  }

  void _saveAddress() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_isLocationPicked || _selectedLatLng == null) {
      CustomSnackbars.showInfoSnack(
        context: context,
        title: "Location Required",
        message: "Please select your delivery location on the map.",
      );
      return;
    }

    final isWithinServiceArea = LocationValidator.isWithinServiceArea(
      _selectedLatLng!.latitude,
      _selectedLatLng!.longitude,
    );
    if (!isWithinServiceArea) {
      final distance = LocationValidator.calculateDistance(
        _selectedLatLng!.latitude,
        _selectedLatLng!.longitude,
        ANAKAPALLI_LATITUDE,
        ANAKAPALLI_LONGITUDE,
      );
      CustomSnackbars.showInfoSnack(
        context: context,
        title: "Out of Service Area",
        message:
            "This location is ${distance.toStringAsFixed(1)} km away, outside our "
            "${SERVICE_RADIUS_KM.toStringAsFixed(0)} km delivery radius. Please pick a closer location.",
      );
      return;
    }

    final stateText = stateController.text.trim();
    final cityText = cityController.text.trim();

    final matchedState = _matchState(stateText);
    if (matchedState == null) {
      CustomSnackbars.showInfoSnack(
        context: context,
        title: "Out of Service Area",
        message:
            "We currently don't deliver to $stateText. Please check the State and try again.",
      );
      return;
    }

    final matchedCity = _matchCity(cityText, matchedState);
    if (matchedCity == null) {
      return;
    }

    final addressLine1 = joinAddressParts([
      houseController.text,
      landmarkController.text,
      streetController.text,
    ]);

    final payload = {
      "addressLine1": addressLine1,
      "cityId": matchedCity.id,
      "stateId": matchedState.id,
      "country": "IN",
      "postalCode": pincodeController.text.trim(),
      "latitude": _selectedLatLng!.latitude,
      "longitude": _selectedLatLng!.longitude,
    };
    context.read<SaveAddressCubit>().saveAddress(payload, context);
  }

  Widget _buildLocationPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "Delivery Location",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            const Text('*', style: TextStyle(color: Colors.red)),
          ],
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickLocation,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: _isLocationPicked ? null : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.location_pin,
                  color:
                      _isLocationPicked
                          ? AppColor.PrimaryColor
                          : Colors.grey.shade600,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _isLocationPicked && _selectedLatLng != null
                        ? "Location selected (${_selectedLatLng!.latitude.toStringAsFixed(5)}, "
                            "${_selectedLatLng!.longitude.toStringAsFixed(5)})"
                        : "Select delivery location on map",
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          _isLocationPicked
                              ? null
                              : Colors.grey.shade600,
                    ),
                  ),
                ),
                Text(
                  _isLocationPicked ? "Change" : "Select",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColor.PrimaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
    bool required = true,
    bool enabled = true,
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
                const Text('*', style: TextStyle(color: Colors.red)),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            enabled: enabled,
            maxLines: maxLines,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            validator: validator,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: InputDecoration(
              filled: !enabled,
              fillColor: Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade400),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade400),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
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
                borderSide: const BorderSide(color: Colors.red),
              ),
              hintText: 'Enter $label',
              hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            ),
            style: TextStyle(
              fontSize: 14,
              color: enabled ? null : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _applyDefaultPhone();
    _applyDefaultLocation();
    setState(() {
      _selectedLatLng = null;
      _isLocationPicked = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (scaffoldContext) {
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
                      message:
                          state.message.isEmpty
                              ? "Failed to Save Address"
                              : state.message,
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
                      message:
                          state.error.isEmpty
                              ? "Failed to Delete Address"
                              : state.error,
                    );
                  }
                },
              ),
              BlocListener<GetStatesCubit, GetStatesState>(
                listener: (context, state) {
                  if (state is GetStatesSuccess) {
                    setState(() {
                      _states = state.states;
                    });
                    _applyDefaultLocation();
                  } else if (state is GetStatesFailure) {
                    CustomSnackbars.showErrorSnack(
                      context: scaffoldContext,
                      title: "Failed",
                      message:
                          state.error.isEmpty
                              ? "Failed to load states"
                              : state.error,
                    );
                  }
                },
              ),
              BlocListener<GetCitiesCubit, GetCitiesState>(
                listener: (context, state) {
                  if (state is GetCitiesSuccess && state.stateId == null) {
                    setState(() {
                      _allCities = state.cities;
                    });
                    _applyDefaultLocation();
                  } else if (state is GetCitiesFailure) {
                    CustomSnackbars.showErrorSnack(
                      context: scaffoldContext,
                      title: "Failed",
                      message:
                          state.error.isEmpty
                              ? "Failed to load cities"
                              : state.error,
                    );
                  }
                },
              ),
              BlocListener<CurrentCustomerCubit, CurrentCustomerState>(
                listener: (context, state) {
                  if (state is CurrentCustomerLoaded) {
                    _applyDefaultPhone();
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
                    autovalidateMode: AutovalidateMode.onUserInteraction,
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
                        _buildLocationPicker(),
                        const SizedBox(height: 16),
                        _buildTextField(
                          label: "Full Name",
                          controller: nameController,
                          validator:
                              (v) =>
                                  (v == null || v.trim().isEmpty)
                                      ? 'Please enter your name'
                                      : null,
                        ),
                        _buildTextField(
                          label: "Phone Number",
                          controller: phoneController,
                          enabled: false,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
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
                        _buildTextField(
                          label: "House No. / Building",
                          controller: houseController,
                          validator:
                              (v) =>
                                  (v == null || v.trim().isEmpty)
                                      ? 'Please enter house/building details'
                                      : null,
                        ),
                        _buildTextField(
                          label: "Street / Locality",
                          controller: streetController,
                          validator:
                              (v) =>
                                  (v == null || v.trim().isEmpty)
                                      ? 'Please enter street/locality'
                                      : null,
                        ),
                        _buildTextField(
                          label: "Landmark (optional)",
                          controller: landmarkController,
                          required: false,
                        ),
                        _buildTextField(
                          label: "State",
                          controller: stateController,
                          enabled: false,
                          validator:
                              (v) =>
                                  (v == null || v.trim().isEmpty)
                                      ? 'Please enter your state'
                                      : null,
                        ),
                        _buildTextField(
                          label: "City",
                          controller: cityController,
                          enabled: false,
                          validator:
                              (v) =>
                                  (v == null || v.trim().isEmpty)
                                      ? 'Please enter your city'
                                      : null,
                        ),
                        _buildTextField(
                          label: "Pincode",
                          controller: pincodeController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
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
                          builder:
                              (context, state) => SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed:
                                      state is SaveAddressLoading
                                          ? null
                                          : _saveAddress,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColor.PrimaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  child:
                                      state is SaveAddressLoading
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
      },
    );
  }
}
