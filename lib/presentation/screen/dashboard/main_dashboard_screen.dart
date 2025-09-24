import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_basket/components/custom_topbar.dart';
import 'package:local_basket/core/constants/colors.dart';
import 'package:local_basket/presentation/cubit/offers/restaurant_offers/get_restaurant_offers/restaurant_offers_cubit.dart';
import 'package:local_basket/presentation/screen/profile/profile_screen.dart';
import 'package:local_basket/presentation/screen/widgets/dashboard/offersCard_widget.dart';
import 'package:local_basket/presentation/screen/widgets/loginPrompt.dart';
import 'dashboard_screen.dart';

class MainDashboard extends StatelessWidget {
  final bool isGuest;
  const MainDashboard({super.key, this.isGuest = false});

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
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () {
              if (isGuest) {
                showLoginPromptSheet(context);
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfileScreen(isGuest: isGuest),
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
          const OffersCarousel(),

          const SizedBox(height: 24),

          // Food Banner
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
                  builder: (_) => DashboardScreen(isGuest: isGuest),
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // Grocery Banner
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

          // Fresh Meat Banner
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
        ],
      ),
    );
  }
}



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
class _UnderDevelopmentScreen extends StatelessWidget {
  final String title;
  const _UnderDevelopmentScreen({required this.title});

  IconData _getIcon() {
    switch (title.toLowerCase()) {
      case "grocery":
        return Icons.local_grocery_store;
      case "fresh meat":
        return Icons.set_meal;
      default:
        return Icons.fastfood;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.White,
      appBar: CustomAppBar(
       title: title,
      ),
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
                "$title\nComing Soon!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColor.PrimaryColor,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "We’re working hard to bring you\npremium $title experience.",
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
