import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:local_basket/components/custom_snackbar.dart';
import 'package:local_basket/components/custom_topbar.dart';
import 'package:local_basket/core/constants/colors.dart';
import 'package:local_basket/presentation/cubit/complaints/create_complaints_cubit.dart';
import 'package:local_basket/presentation/cubit/complaints/create_complaints_state.dart';

class ComplaintsScreen extends StatefulWidget {
  final int? orderId;
  final int? b2bId;
  final bool fromOrderHistory;

  const ComplaintsScreen(
      {super.key, this.orderId, this.b2bId, this.fromOrderHistory = false});

  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _orderIdController = TextEditingController();
  final TextEditingController _b2bIdController = TextEditingController();
  String _complaintType = 'SERVICE';

  @override
  void initState() {
    super.initState();
    if (widget.orderId != null) {
      _orderIdController.text = widget.orderId.toString();
    }
    if (widget.b2bId != null) {
      _b2bIdController.text = widget.b2bId.toString();
    }
    if (widget.fromOrderHistory) {
      _complaintType = 'PRODUCT';
    } else {
      _complaintType = 'SERVICE';
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    _orderIdController.dispose();
    _b2bIdController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final int? orderId = widget.orderId;
    final int? b2bId = widget.b2bId;

    final payload = {
      'title': _subjectController.text.trim(),
      'description': _messageController.text.trim(),
      if (orderId != null) 'orderId': orderId,
      if (b2bId != null) 'b2bId': b2bId,
      'complaintType': _complaintType,
    };

    context.read<CreateComplaintCubit>().createComplaint(payload);
  }

   void _makePhoneCall(String phoneNumber) async {
    print("Phone Number: $phoneNumber");
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        throw 'Could not launch phone call';
      }
    } catch (e) {
      debugPrint('Error launching phone call: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CreateComplaintCubit, CreateComplaintState>(
      listener: (context, state) {
        if (state is CreateComplaintSuccess) {
          CustomSnackbars.showSuccessSnack(
            context: context,
            title: 'Submitted',
            message: 'Your complaint has been recorded.',
          );
          Navigator.pop(context);
        } else if (state is CreateComplaintFailure) {
          CustomSnackbars.showErrorSnack(
            context: context,
            title: 'Failed',
            message: state.error,
          );
        }
      },
      builder: (context, state) {
        final loading = state is CreateComplaintLoading;
        return Scaffold(
          backgroundColor: AppColor.White,
          appBar: const CustomAppBar(title: 'Complaints'),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text('Let us know your issue',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                      )),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _subjectController,
                    decoration: InputDecoration(
                      labelText: 'Subject',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Please enter a subject'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _messageController,
                    minLines: 4,
                    maxLines: 8,
                    decoration: InputDecoration(
                      labelText: 'Message',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Please describe your issue'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _complaintType,
                    decoration: InputDecoration(
                      labelText: 'Complaint Type',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: widget.fromOrderHistory
                        ? const [
                            DropdownMenuItem(
                                value: 'PRODUCT', child: Text('Order Item')),
                            DropdownMenuItem(
                                value: 'RESTAURANT', child: Text('Restaurant')),
                          ]
                        : const [
                            DropdownMenuItem(
                                value: 'SERVICE', child: Text('Service')),
                            DropdownMenuItem(
                                value: 'DELIVERY', child: Text('Delivery')),
                            DropdownMenuItem(
                                value: 'GENAERAL', child: Text('General')),
                            DropdownMenuItem(
                                value: 'ORDER_REJECTED',
                                child: Text('Order Rejected')),
                            DropdownMenuItem(
                                value: 'OTHER', child: Text('Other')),
                          ],
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _complaintType = v);
                    },
                  ),
                  // Order ID and B2B ID fields intentionally hidden for all entry paths
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.PrimaryColor,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Submit Complaint'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _makePhoneCall('8185000440'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.SecondaryColor,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          :  Text('Make a Call', style: TextStyle(color: AppColor.White, fontWeight: FontWeight.bold, fontSize: 14),),
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
}
