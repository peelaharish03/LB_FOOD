import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_basket/data/model/offers/restaurant_offers/restaurant_offers_model.dart';
import 'package:local_basket/presentation/cubit/offers/restaurant_offers/get_restaurant_offers/restaurant_offers_cubit.dart';
import 'package:local_basket/presentation/cubit/offers/restaurant_offers/get_restaurant_offers/restaurant_offers_state.dart';
import 'package:local_basket/presentation/screen/dashboard/dashboard_screen.dart';

class OffersCarousel extends StatefulWidget {
  const OffersCarousel({super.key});

  @override
  State<OffersCarousel> createState() => _OffersCarouselState();
}

class _OffersCarouselState extends State<OffersCarousel> {
  final PageController _pageController = PageController(
    viewportFraction: 0.85,
    initialPage: 1000,
  );

  double _currentPage = 1000.0;
  Timer? _autoScrollTimer;
  bool _isUserInteracting = false;

  @override
  void initState() {
    super.initState();

    // Fetch offers from API using Cubit
    context.read<RestaurantOffersCubit>().fetchRestaurantOffers();

    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page ?? _currentPage;
      });
    });

    _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!_pageController.hasClients || _isUserInteracting) return;

      _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RestaurantOffersCubit, RestaurantOffersState>(
      builder: (context, state) {
        if (state is RestaurantOffersLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is RestaurantOffersError) {
          return Center(child: Text(state.message));
        } else if (state is RestaurantOffersLoaded) {
          final offers = state.offers.data?.content ?? [];

          if (offers.isEmpty) {
            return const Center(child: Text("No offers available"));
          }

          return GestureDetector(
            onPanDown: (_) => _isUserInteracting = true,
            onPanCancel: () => _isUserInteracting = false,
            onPanEnd: (_) => _isUserInteracting = false,
            child: Column(
              children: [
                SizedBox(
                  height: 160,
                  child: PageView.builder(
                    controller: _pageController,
                    itemBuilder: (context, index) {
                      final Content offer = offers[index % offers.length];

                      // Dynamic UI: choose colors based on offerType
                      final gradientColors =
                          _getGradientColors(offer.offerType);
                      final accentColor = gradientColors.last;

                      final double scale = (_currentPage - index).abs() < 1.0
                          ? 1 - (_currentPage - index).abs() * 0.1
                          : 0.9;

                      return Transform.scale(
                        scale: scale,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOutQuint,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: OffersCard(
                            tag: offer.couponCode ?? "OFFER",
                            title: offer.name ?? "",
                            subtitle: offer.description ?? "",
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      DashboardScreen(couponCode: offer.couponCode),
                                ),
                              );
                            },
                            gradientColors: gradientColors,
                            accentColor: accentColor,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  // Helper to map offer type → gradient
  List<Color> _getGradientColors(String? offerType) {
    switch (offerType) {
      case "DISCOUNT":
        return [const Color(0xFFE0F7FA), const Color(0xFF00ACC1)];
      case "FREE_DELIVERY":
        return [const Color(0xFFE8F5E9), const Color(0xFF43A047)];
      case "CASHBACK":
        return [const Color(0xFFFFF3E0), const Color(0xFFFB8C00)];
      default:
        return [Colors.grey.shade200, const Color.fromARGB(255, 109, 200, 233)];
    }
  }
}

class OffersCard extends StatelessWidget {
  final String tag;
  final String title;
  final String subtitle;
  final VoidCallback onPressed;
  final List<Color> gradientColors;
  final Color accentColor;

  const OffersCard({
    super.key,
    required this.tag,
    required this.title,
    required this.subtitle,
    required this.onPressed,
    required this.gradientColors,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 140,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor.withOpacity(0.2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 28,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onPressed: onPressed,
                    child: const Text(
                      "Order Now",
                      style: TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
