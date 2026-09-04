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
import 'package:local_basket/presentation/cubit/address/updateAddress/updateAddress_cubit.dart';
import 'package:local_basket/presentation/cubit/address/updateAddress/updateAddress_state.dart';
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

  /// True when opened from the cart to pick a delivery address (tapping a
  /// saved address pops back with it). False (default, e.g. from Profile)
  /// keeps the user on this screen and just updates the default.
  final bool selectionMode;

  const AddressScreen({
    super.key,
    this.selectedAddress,
    this.selectionMode = false,
  });
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

  // Non-null while the "Add New Address" tab is being reused to edit an
  // existing saved address. Controls the screen title, the submit button
  // label, and whether submit hits the save (POST) or update (PUT) API.
  Content? _editingAddress;

  // Address type picked via the selectable Home / Workplace / Others chips.
  // Sent as `addressType` to the save (POST) and update (PUT) APIs.
  String _selectedAddressType = 'HOME';

  bool get _isEditing => _editingAddress != null;

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

  // Maps whatever the backend stored for addressType onto one of the three
  // chip values so the right chip highlights when editing.
  String _normalizeAddressType(String? raw) {
    final value = (raw ?? '').trim().toUpperCase();
    if (value.isEmpty || value == 'HOME') return 'HOME';
    if (value == 'WORK' || value == 'OFFICE' || value == 'WORKPLACE') {
      return 'WORK';
    }
    return 'OTHER';
  }

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

  /// Prefills the "Add New Address" form with an existing address and
  /// switches to that tab so the same form can be reused to edit it.
  void _startEditingAddress(Content address) {
    final item = address.address;
    setState(() {
      _editingAddress = address;
      nameController.text = item?.name ?? address.userName ?? '';
      phoneController.text = _normalizePhoneNumber(item?.mobileNumber);
      houseController.text = item?.line1 ?? '';
      streetController.text = item?.line2 ?? '';
      landmarkController.text = '';
      _selectedAddressType = _normalizeAddressType(item?.addressType);
      if ((item?.state ?? '').isNotEmpty) stateController.text = item!.state!;
      if ((item?.city ?? '').isNotEmpty) cityController.text = item!.city!;
      pincodeController.text = item?.postalCode ?? '';
      // Editing keeps the existing pin unless the user re-picks it.
      _selectedLatLng = null;
      _isLocationPicked = false;
    });
    _applyDefaultLocation();
    _applyDefaultPhone();
    _tabController.animateTo(1);
  }

  void _saveAddress() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // A fresh address must be pinned on the map. When editing, the user may
    // keep the existing pin; only validate if they picked a new one.
    if (!_isEditing && (!_isLocationPicked || _selectedLatLng == null)) {
      CustomSnackbars.showInfoSnack(
        context: context,
        title: "Location Required",
        message: "Please select your delivery location on the map.",
      );
      return;
    }

    if (_selectedLatLng != null) {
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

    if (_isEditing) {
      final addressId = _editingAddress!.id;
      if (addressId == null || addressId.isEmpty) return;

      final line2 = streetController.text.trim();
      final fullText = joinAddressParts([
        addressLine1,
        line2,
        cityText,
        stateText,
        pincodeController.text.trim(),
      ]);

      final payload = <String, dynamic>{
        "name": nameController.text.trim(),
        "addressType": _selectedAddressType,
        "mobileNumber": phoneController.text.trim(),
        "line1": addressLine1,
        "line2": line2,
        "stateId": matchedState.id,
        "cityId": matchedCity.id,
        "country": "IN",
        "postalCode": pincodeController.text.trim(),
        "fullText": fullText,
      };
      if ((_editingAddress!.userId ?? '').isNotEmpty) {
        payload["userId"] = _editingAddress!.userId;
      }
      if (_selectedLatLng != null) {
        payload["latitude"] = _selectedLatLng!.latitude;
        payload["longitude"] = _selectedLatLng!.longitude;
      }
      context.read<UpdateAddressCubit>().updateAddress(
        addressId,
        payload,
        context,
      );
      return;
    }

    final payload = {
      "addressLine1": addressLine1,
      "cityId": matchedCity.id,
      "stateId": matchedState.id,
      "country": "IN",
      "postalCode": pincodeController.text.trim(),
      "latitude": _selectedLatLng!.latitude,
      "longitude": _selectedLatLng!.longitude,
      "name": nameController.text.trim(),
      "addressType": _selectedAddressType,
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

  // Home / Workplace / Others shown side by side; exactly one stays selected
  // and its value ("HOME" / "WORK" / "OTHER") is sent as `addressType`.
  Widget _buildAddressTypeSelector() {
    const options = [
      ['Home', 'HOME'],
      ['Workplace', 'WORK'],
      ['Others', 'OTHER'],
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "Address Type",
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
        Row(
          children: [
            for (final option in options) ...[
              Expanded(
                child: InkWell(
                  onTap:
                      () => setState(() => _selectedAddressType = option[1]),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color:
                          _selectedAddressType == option[1]
                              ? AppColor.PrimaryColor.withValues(alpha: 0.10)
                              : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color:
                            _selectedAddressType == option[1]
                                ? AppColor.PrimaryColor
                                : Colors.grey.shade400,
                        width: _selectedAddressType == option[1] ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      option[0],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            _selectedAddressType == option[1]
                                ? FontWeight.w600
                                : FontWeight.w400,
                        color:
                            _selectedAddressType == option[1]
                                ? AppColor.PrimaryColor
                                : Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),
              ),
              if (option != options.last) const SizedBox(width: 10),
            ],
          ],
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
    nameController.clear();
    phoneController.clear();
    houseController.clear();
    streetController.clear();
    landmarkController.clear();
    stateController.clear();
    cityController.clear();
    pincodeController.clear();
    setState(() {
      _editingAddress = null;
      _selectedAddressType = 'HOME';
      _selectedLatLng = null;
      _isLocationPicked = false;
    });
    _applyDefaultPhone();
    _applyDefaultLocation();
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
              BlocListener<UpdateAddressCubit, UpdateAddressState>(
                listener: (context, state) {
                  if (state is UpdateAddressSuccess) {
                    CustomSnackbars.showSuccessSnack(
                      context: scaffoldContext,
                      title: "Success",
                      message: "Address Updated Successfully",
                    );
                    _clearForm();
                    _fetchAddresses();
                    _tabController.animateTo(0);
                  } else if (state is UpdateAddressFailure) {
                    CustomSnackbars.showErrorSnack(
                      context: scaffoldContext,
                      title: "Failed",
                      message:
                          state.error.isEmpty
                              ? "Failed to Update Address"
                              : state.error,
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
                    // Keep the visible list in sync with the server even when
                    // the delete is reported as failed.
                    _fetchAddresses();
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
                  selectionMode: widget.selectionMode,
                  onAddNewAddressTap: () {
                    _tabController.animateTo(1);
                  },
                  onEditAddress: _startEditingAddress,
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
                          _isEditing ? "Edit Address" : "Add New Address",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildLocationPicker(),
                        const SizedBox(height: 16),
                        _buildAddressTypeSelector(),
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
                          required: !_isEditing,
                          validator:
                              (v) =>
                                  (!_isEditing &&
                                          (v == null || v.trim().isEmpty))
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
                          builder: (context, saveState) {
                            return BlocBuilder<
                              UpdateAddressCubit,
                              UpdateAddressState
                            >(
                              builder: (context, updateState) {
                                final isLoading =
                                    saveState is SaveAddressLoading ||
                                    updateState is UpdateAddressLoading;
                                return SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: isLoading ? null : _saveAddress,
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
                                        isLoading
                                            ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child:
                                                  CupertinoActivityIndicator(
                                                    color: Colors.white,
                                                  ),
                                            )
                                            : Text(
                                              _isEditing
                                                  ? "Edit Address"
                                                  : "Save Address",
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                  ),
                                );
                              },
                            );
                          },
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
