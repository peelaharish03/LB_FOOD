import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:local_basket/components/custom_snackbar.dart';
import 'package:local_basket/components/custom_topbar.dart';
import 'package:local_basket/core/constants/colors.dart';
import 'package:local_basket/presentation/cubit/authentication/currentcustomer/get/current_customer_cubit.dart';
import 'package:local_basket/presentation/cubit/authentication/currentcustomer/get/current_customer_state.dart';

class ComplaintsScreen extends StatefulWidget {
  final Object? orderId;
  final Object? b2bId;
  final bool fromOrderHistory;

  const ComplaintsScreen({
    super.key,
    this.orderId,
    this.b2bId,
    this.fromOrderHistory = false,
  });

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
  bool _sending = false;

  static const String _whatsappNumber = '918185000440';

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
    context.read<CurrentCustomerCubit>().GetCurrentCustomer(context);
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    _orderIdController.dispose();
    _b2bIdController.dispose();
    super.dispose();
  }

  String _complaintTypeLabel() {
    switch (_complaintType) {
      case 'PRODUCT':
        return 'Order Item';
      case 'RESTAURANT':
        return 'Restaurant';
      case 'DELIVERY':
        return 'Delivery';
      case 'GENAERAL':
        return 'General';
      case 'ORDER_REJECTED':
        return 'Order Rejected';
      case 'OTHER':
        return 'Other';
      default:
        return 'Service';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Send Complaint'),
            content: const Text(
              'This will open WhatsApp to send your complaint. Do you want to continue?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Yes'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    await _sendComplaintOnWhatsApp();
  }

  Future<void> _sendComplaintOnWhatsApp() async {
    if (!mounted) return;
    setState(() => _sending = true);

    final customerState = context.read<CurrentCustomerCubit>().state;
    final userNumber =
        customerState is CurrentCustomerLoaded
            ? (customerState.currentCustomerModel.mobile ?? 'Not available')
            : 'Not available';

    final buffer =
        StringBuffer()
          ..writeln('New Complaint')
          ..writeln('User Number: $userNumber')
          ..writeln('Complaint Type: ${_complaintTypeLabel()}')
          ..writeln('Subject: ${_subjectController.text.trim()}')
          ..writeln('Message: ${_messageController.text.trim()}');

    if (widget.orderId != null) {
      buffer.writeln('Order ID: ${widget.orderId}');
    }
    if (widget.b2bId != null) {
      buffer.writeln('B2B ID: ${widget.b2bId}');
    }

    final message = Uri.encodeComponent(buffer.toString().trim());
    final whatsappUri = Uri.parse(
      'https://wa.me/$_whatsappNumber?text=$message',
    );

    try {
      final launched = await launchUrl(
        whatsappUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) throw 'Could not launch WhatsApp';
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('Error launching WhatsApp: $e');
      if (mounted) {
        CustomSnackbars.showErrorSnack(
          context: context,
          title: 'Failed',
          message: 'Could not open WhatsApp. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
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
    final loading = _sending;
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
              Text(
                'Let us know your issue',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _subjectController,
                decoration: InputDecoration(
                  labelText: 'Subject',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator:
                    (v) =>
                        (v == null || v.trim().isEmpty)
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
                validator:
                    (v) =>
                        (v == null || v.trim().isEmpty)
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
                items:
                    widget.fromOrderHistory
                        ? const [
                          DropdownMenuItem(
                            value: 'PRODUCT',
                            child: Text('Order Item'),
                          ),
                          DropdownMenuItem(
                            value: 'RESTAURANT',
                            child: Text('Restaurant'),
                          ),
                        ]
                        : const [
                          DropdownMenuItem(
                            value: 'SERVICE',
                            child: Text('Service'),
                          ),
                          DropdownMenuItem(
                            value: 'DELIVERY',
                            child: Text('Delivery'),
                          ),
                          DropdownMenuItem(
                            value: 'GENAERAL',
                            child: Text('General'),
                          ),
                          DropdownMenuItem(
                            value: 'ORDER_REJECTED',
                            child: Text('Order Rejected'),
                          ),
                          DropdownMenuItem(
                            value: 'OTHER',
                            child: Text('Other'),
                          ),
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
                      horizontal: 16,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child:
                      loading
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
                      horizontal: 16,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child:
                      loading
                          ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : Text(
                            'Make a Call',
                            style: TextStyle(
                              color: AppColor.White,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
