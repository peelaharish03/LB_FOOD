import 'package:flutter/material.dart';
import 'package:local_basket/components/custom_topbar.dart';
import 'package:local_basket/core/constants/colors.dart';
import 'package:local_basket/presentation/screen/notifications/notifications_screen.dart';
import 'package:local_basket/presentation/screen/profile/profile_screen.dart';
import 'package:local_basket/presentation/screen/widgets/dashboard/offersCard_widget.dart';
import 'package:local_basket/presentation/screen/widgets/loginPrompt.dart';
import 'dashboard_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:local_basket/core/utils/push_notication_services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_basket/presentation/cubit/authentication/currentcustomer/update/update_current_customer_cubit.dart';

class MainDashboard extends StatefulWidget {
  final bool isGuest;
  const MainDashboard({super.key, this.isGuest = false});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}


class _MainDashboardState extends State<MainDashboard> {
  final NotificationServices _notificationServices = NotificationServices();

  @override
  void initState() {
    super.initState();
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    await _notificationServices.forgroundMessage();

    if (!mounted) return;
    await _notificationServices.firebaseInit(context);

    if (!mounted) return;
    await _notificationServices.setupInteractMessage(context);

    if (!mounted) return;
    await _notificationServices.isRefreshToken();

    _notificationServices.getDeviceToken().then((fcmToken) async {
      if (!mounted) return;
      if (fcmToken != null && !widget.isGuest) {
        final prefs = await SharedPreferences.getInstance();
        final savedAuthToken = prefs.getString('TOKEN');
        if (savedAuthToken != null && savedAuthToken.isNotEmpty) {
          print('Updating customer with FCM token: $fcmToken');
          final payload = {
            'fullName': '',
            'email': '',
            'local_basket': true,
            'fcmToken': fcmToken,
          };
          if (!mounted) return;
          context
              .read<UpdateCurrentCustomerCubit>()
              .updateCustomer(payload, context);
        }
      }
    });
  }

  void showLoginPromptSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (context) => const LoginPromptSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.White,
      appBar: CustomAppBar(
        title: 'Localbasket',
        showBackButton: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
            onPressed: () {
              if (widget.isGuest) {
                showLoginPromptSheet(context);
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () {
              if (widget.isGuest) {
                showLoginPromptSheet(context);
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfileScreen(isGuest: widget.isGuest),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          /// 🔥 Offers Carousel
          OffersCarousel(isGuest: widget.isGuest),

          const SizedBox(height: 24),

          /// 🍽️ Food Banner
          _BannerCard(
            title: "Food",
            subtitle: "Your online aisle of taste",
            imageUrl:
                "https://images.pexels.com/photos/958545/pexels-photo-958545.jpeg",
            gradient: [Color(0xFF1860EF), Color(0xFF5A95F5)],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DashboardScreen(isGuest: widget.isGuest),
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          _BannerCard(
            title: "Special Zone",
            subtitle: "Exclusive deals and limited-time offers",
            imageUrl:
                "https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=1200&q=80",
            gradient: [Color(0xFFFF8C00), Color(0xFFFFC107)],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const _UnderDevelopmentScreen(title: "Special Zone"),
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          /// 🛒 Grocery Banner

          /// 🥩 Fresh Meat Banner
          _BannerCard(
            title: "Fresh Meat",
            subtitle: "Top quality, handpicked cuts",
            imageUrl:
                "https://images.pexels.com/photos/10201880/pexels-photo-10201880.jpeg",
            gradient: [Color(0xFFE53935), Color(0xFFD81B60)],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const _UnderDevelopmentScreen(title: "Fresh Meat"),
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          _BannerCard(
            title: "Grocery",
            subtitle: "The most coveted grocery brands",
            imageUrl:
                "https://images.pexels.com/photos/264636/pexels-photo-264636.jpeg",
            gradient: [Color(0xFF9C27B0), Color(0xFF673AB7)],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const _UnderDevelopmentScreen(title: "Grocery"),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// 🔹 Banner Card Widget
class _BannerCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imageUrl;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _BannerCard({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          image: DecorationImage(
            image: NetworkImage(imageUrl),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.4),
              BlendMode.darken,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 🚧 Under Development Screen
class _UnderDevelopmentScreen extends StatefulWidget {
  final String title;
  const _UnderDevelopmentScreen({required this.title});

  @override
  State<_UnderDevelopmentScreen> createState() =>
      _UnderDevelopmentScreenState();
}

class _UnderDevelopmentScreenState extends State<_UnderDevelopmentScreen> {
  final _notificationServices = NotificationServices();

  Future<void> _initFcmAndUpdate() async {
    await _notificationServices.requestNotificationPermissions();
    await _notificationServices.enableForegroundNotifications();
    _notificationServices.initializeFirebaseMessaging(context);
    await _notificationServices.setupNotificationInteraction(context);

    final token = await _notificationServices.getDeviceToken();
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final savedAuthToken = prefs.getString('TOKEN');

    if (token != null && savedAuthToken != null && savedAuthToken.isNotEmpty) {
      _updateFcmToken(token);
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      final prefs = await SharedPreferences.getInstance();
      final savedAuthToken = prefs.getString('TOKEN');
      if (savedAuthToken != null && savedAuthToken.isNotEmpty) {
        _updateFcmToken(newToken);
      }
    });
  }

  void _updateFcmToken(String token) {
    // implement your logic to update FCM token
  }

  @override
  void initState() {
    super.initState();
    _initFcmAndUpdate();
  }

  IconData _getIcon() {
    switch (widget.title.toLowerCase()) {
      case "special zone":
        return Icons.star;

      case "fresh meat":
        return Icons.set_meal;
      case "grocery":
        return Icons.local_grocery_store;
      default:
        return Icons.fastfood;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.White,
      appBar: CustomAppBar(title: widget.title),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getIcon(),
                size: 100,
                color: AppColor.PrimaryColor,
              ),
              const SizedBox(height: 20),
              Text(
                "${widget.title}\nComing Soon!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColor.PrimaryColor,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "We’re working hard to bring you\npremium ${widget.title} experience.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.PrimaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: () {},
                child: const Text(
                  "Notify Me",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
