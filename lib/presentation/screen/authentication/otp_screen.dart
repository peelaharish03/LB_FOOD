import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';
import 'package:local_basket/components/custom_button.dart';
import 'package:local_basket/components/custom_snackbar.dart';
import 'package:local_basket/core/constants/colors.dart';
import 'package:local_basket/core/constants/img_const.dart';
import 'package:local_basket/presentation/cubit/authentication/currentcustomer/get/current_customer_cubit.dart';
import 'package:local_basket/presentation/cubit/authentication/currentcustomer/get/current_customer_state.dart';
import 'package:local_basket/presentation/cubit/authentication/login/trigger_otp_cubit.dart';
import 'package:local_basket/presentation/cubit/authentication/login/trigger_otp_state.dart';
import 'package:local_basket/presentation/cubit/authentication/signin/sigin_cubit.dart';
import 'package:local_basket/presentation/cubit/authentication/signin/signin_state.dart';
import 'package:local_basket/presentation/screen/authentication/login_screen.dart';
import 'package:local_basket/presentation/screen/authentication/nameInput_screen.dart';
import 'package:local_basket/presentation/screen/dashboard/main_dashboard_screen.dart';

// ignore: must_be_immutable
class OtpScreen extends StatefulWidget {
  final String mobileNumber;
  String otp;
  String fullName;
  String otpValue;

  OtpScreen({
    super.key,
    required this.mobileNumber,
    required this.otp,
    required this.otpValue,
    required this.fullName,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController otpController = TextEditingController();
  bool _hasNavigated = false;

  void _navigateBasedOnCustomerStatus(BuildContext context) {
    context.read<CurrentCustomerCubit>().GetCurrentCustomer(context);
  }

  @override
  void dispose() {
    otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      body: MultiBlocListener(
        listeners: [
          BlocListener<SignInCubit, SignInState>(
            listener: (context, state) {
              if (state is SignInLoading) {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const Center(
                    child: CupertinoActivityIndicator(),
                  ),
                );
              } else {
                Navigator.of(context, rootNavigator: true).pop();
              }

              if (state is SignInLoaded) {
                _navigateBasedOnCustomerStatus(context);
              } else if (state is SignInError) {
                CustomSnackbars.showErrorSnack(
                  context: context,
                  title: "Failed",
                  message:
                      "The OTP you entered is incorrect. Please try again.",
                );
              }
            },
          ),
          BlocListener<TriggerOtpCubit, TriggerOtpState>(
            listener: (context, state) {
              if (state is ResendOtpLoaded) {
                setState(() {
                  widget.otp = state.resendOtp.otp ?? '';
                });
              }
            },
          ),
          BlocListener<CurrentCustomerCubit, CurrentCustomerState>(
            listener: (context, state) {
              if (state is CurrentCustomerLoaded && !_hasNavigated) {
                _hasNavigated = true;
                if (state.currentCustomerModel.eato == true) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const MainDashboard()),
                  );
                } else {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const NameInputScreen()),
                  );
                }
              } else if (state is CurrentCustomerError) {
                CustomSnackbars.showErrorSnack(
                  context: context,
                  title: "Failed",
                  message: "Something went wrong",
                );
              }
            },
          ),
        ],
        child: Stack(
          children: [
            /// Gradient Background same as login
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF914D), Color(0xFFFE5E54)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

            /// Main content
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          SizedBox(height: height * 0.08),

                          /// App Logo & Tagline
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 48,
                                backgroundColor: Colors.white,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Image.asset(appLogo),
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                "Verify OTP",
                                style: GoogleFonts.poppins(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Confirm your number to continue",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: height * 0.07),

                          /// White input card (same layout as login)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Enter the 6-digit OTP sent to",
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade900,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Text(
                                      "+91 ${widget.mobileNumber}",
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    const Spacer(),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) =>
                                                  const LoginScreen()),
                                        );
                                      },
                                      child: Text(
                                        "Change",
                                        style: GoogleFonts.poppins(
                                          color: AppColor.PrimaryColor,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (widget.otp != 'true') ...[
                                  const SizedBox(height: 10),
                                  Center(
                                    child: Text(
                                      widget.otp,
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 24),

                                /// OTP Input
                                Center(
                                  child: Pinput(
                                    controller: otpController,
                                    length: 6,
                                    onCompleted: (value) {
                                      if (value.length == 6) {
                                        context.read<SignInCubit>().signIn(
                                              context,
                                              widget.mobileNumber,
                                              value,
                                              widget.fullName,
                                            );
                                      }
                                    },
                                    defaultPinTheme: PinTheme(
                                      width: 48,
                                      height: 48,
                                      textStyle: GoogleFonts.poppins(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                        color: AppColor.PrimaryColor,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: Colors.grey.shade300),
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  /// Sticky Button Section (same style as login)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 20),
                    child: Column(
                      children: [
                        BlocBuilder<SignInCubit, SignInState>(
                          builder: (context, state) {
                            return CustomButton(
                              buttonText: "Verify & Continue",
                              isLoading: state is SignInLoading,
                              onPressed: () {
                                if (otpController.text.length == 6) {
                                  context.read<SignInCubit>().signIn(
                                        context,
                                        widget.mobileNumber,
                                        otpController.text,
                                        widget.fullName,
                                      );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          "Please enter a valid 6-digit OTP."),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 14),
                        GestureDetector(
                          onTap: () {
                            context
                                .read<TriggerOtpCubit>()
                                .resendOtp(context, widget.mobileNumber);
                          },
                          child: Text(
                            "Didn’t receive it? Resend OTP",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
