import 'dart:async';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:local_basket/core/utils/push_notication_services.dart';
import 'package:local_basket/presentation/cubit/authentication/currentcustomer/get/current_customer_cubit.dart';
import 'package:local_basket/presentation/cubit/authentication/currentcustomer/get/current_customer_state.dart';
import 'package:local_basket/presentation/cubit/authentication/currentcustomer/update/update_current_customer_cubit.dart';
import 'package:local_basket/presentation/screen/authentication/login_screen.dart';
import 'package:local_basket/presentation/screen/authentication/nameInput_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_basket/presentation/screen/dashboard/main_dashboard_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _videoController;
  late Future<void> _videoInitFuture;
  bool _navigateManually = false;
  final NotificationServices _notificationServices = NotificationServices();

  @override
  void initState() {
    super.initState();
    initNotifications();
    _videoController =
        VideoPlayerController.asset('assets/images/videos/food.mp4');
    _videoInitFuture = _videoController.initialize().then((_) {
      _videoController.setLooping(true);
      _videoController.setVolume(0.0);
      _videoController.play();
      setState(() {});
    });

    _startNavigationLogic();
  }

  Future<void> _startNavigationLogic() async {
    await Future.delayed(const Duration(seconds: 4));

    final prefs = await SharedPreferences.getInstance();

    String? deviceId = await _getUniqueDeviceId();
    if (deviceId != null) {
      await prefs.setString('device_id', deviceId);
    }
    print("Device ID: $deviceId");

    final token = prefs.getString('TOKEN');
    final isFirstTime = prefs.getBool('isFirstTime') ?? true;

    if (isFirstTime) {
      await prefs.setBool('isFirstTime', false);
      _navigateTo(const LoginScreen());
      return;
    }

    if (token == null || token.isEmpty) {
      _navigateTo(const LoginScreen());
      return;
    }

    await context.read<CurrentCustomerCubit>().GetCurrentCustomer(context);
    setState(() => _navigateManually = true);
  }

  Future<String?> _getUniqueDeviceId() async {
    final deviceInfoPlugin = DeviceInfoPlugin();

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        return androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        return iosInfo.identifierForVendor; // Unique on iOS
      }
    } catch (e) {
      debugPrint("Device ID fetch error: $e");
    }

    return null;
  }

  void _navigateTo(Widget screen) {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  Future<void> initNotifications() async {
    await _notificationServices.requestNotificationPermissions();
    await _notificationServices.forgroundMessage();

    if (!mounted) return;
    await _notificationServices.firebaseInit(context);

    if (!mounted) return;
    await _notificationServices.setupInteractMessage(context);

    if (!mounted) return;
    await _notificationServices.isRefreshToken();

    _notificationServices.getDeviceToken().then((fcmToken) {
      if (!mounted) return;
      if (fcmToken != null) {
        final payload = {
          'fullName': '',
          'email': '',
          'local_basket': true,
          "fcmToken": fcmToken,
        };
        context
            .read<UpdateCurrentCustomerCubit>()
            .updateCustomer(payload, context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CurrentCustomerCubit, CurrentCustomerState>(
      listener: (context, state) {
        if (!_navigateManually) return;

        if (state is CurrentCustomerLoaded) {
          final local_basket = state.currentCustomerModel.eato ?? false;
          _navigateTo(
              local_basket ? const MainDashboard() : const NameInputScreen());
        } else {
          _navigateTo(const LoginScreen());
        }
      },
      child: Scaffold(
        body: FutureBuilder(
          future: _videoInitFuture,
          builder: (context, snapshot) {
            return Stack(
              fit: StackFit.expand,
              children: [
                if (snapshot.connectionState == ConnectionState.done)
                  FittedBox(
                    fit: BoxFit.cover,
                    child: Transform.translate(
                      offset: const Offset(25, 0),
                      child: SizedBox(
                        width: _videoController.value.size.width,
                        height: _videoController.value.size.height,
                        child: VideoPlayer(_videoController),
                      ),
                    ),
                  )
                else
                  Container(color: Colors.black),
                Container(
                  color: Colors.black.withOpacity(0.5),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Localbasket',
                        style: GoogleFonts.montserrat(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Delight Delivered',
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
