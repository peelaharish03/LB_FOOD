import 'package:local_basket/components/custom_button.dart';
import 'package:local_basket/components/custom_snackbar.dart';
import 'package:local_basket/components/custom_topbar.dart';
import 'package:local_basket/core/constants/colors.dart';
import 'package:local_basket/presentation/cubit/authentication/currentcustomer/update/update_current_customer_cubit.dart';
import 'package:local_basket/presentation/cubit/authentication/currentcustomer/update/update_current_customer_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_basket/presentation/screen/dashboard/main_dashboard_screen.dart';

class NameInputScreen extends StatefulWidget {
  final String? initialEmail;

  const NameInputScreen({super.key, this.initialEmail});

  @override
  _NameInputScreenState createState() => _NameInputScreenState();
}

class _NameInputScreenState extends State<NameInputScreen> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  final _formKey = GlobalKey<FormState>();
bool _hasNavigated = false;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    final cubit = context.read<UpdateCurrentCustomerCubit>();

    if (cubit.state.isLoading || _isSubmitting) return;

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      final fullName =
          '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'.trim();

      final payload = {
        'fullName': fullName,
        'email': _emailController.text.trim(),
        'local_basket': true,
        'fcmToken': ''
      };

      cubit.updateCustomer(payload, context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UpdateCurrentCustomerCubit, UpdateCurrentCustomerState>(
      listener: (context, state) {
        if (state.isLoading) return;

        setState(() {
          _isSubmitting = false;
        });

        if (state.error != null && state.error!.isNotEmpty) {
          CustomSnackbars.showErrorSnack(
            context: context,
            title: "Failed",
            message: "Something went wrong",
          );
        } else if (state.data != null && !_hasNavigated) {
          _hasNavigated = true;
          CustomSnackbars.showSuccessSnack(
            context: context,
            title: "Success",
            message: "Profile updated successfully",
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => MainDashboard()),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: CustomAppBar(
            title: "Welcome to Localbasket",
            showBackButton: false,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'First Name',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _firstNameController,
                    hintText: 'Enter first name',
                    validatorMsg: 'Please enter your first name',
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Last Name',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _lastNameController,
                    hintText: 'Enter last name',
                    validatorMsg: 'Please enter your last name',
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Email',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildEmailField(),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColor.PrimaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        'This name will appear on your account and food orders',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      buttonText: "Save Changes",
                      isLoading: state.isLoading,
                      onPressed: state.isLoading ? () {} : _saveChanges,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required String validatorMsg,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          hintText: hintText,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          hintStyle: const TextStyle(color: Colors.grey),
        ),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z ]')),
          LengthLimitingTextInputFormatter(30),
        ],
        validator: (value) {
          if (value == null || value.isEmpty) {
            return validatorMsg;
          }
          return null;
        },
      ),
    );
  }

  Widget _buildEmailField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: _emailController,
        style: const TextStyle(fontSize: 16),
        decoration: const InputDecoration(
          hintText: 'Enter email address',
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          hintStyle: TextStyle(color: Colors.grey),
        ),
        keyboardType: TextInputType.emailAddress,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your email';
          }
          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
            return 'Please enter a valid email';
          }
          return null;
        },
      ),
    );
  }
}
