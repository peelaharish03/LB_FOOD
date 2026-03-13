import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_basket/data/model/offers/restaurant_offers/restaurant_offers_model.dart';
import 'package:local_basket/presentation/cubit/offers/restaurant_offers/get_restaurant_offers/restaurant_offers_cubit.dart';
import 'package:local_basket/presentation/cubit/offers/restaurant_offers/get_restaurant_offers/restaurant_offers_state.dart';
import 'package:local_basket/presentation/cubit/cart/clearCart/clearCart_cubit.dart';
import 'package:local_basket/presentation/screen/dashboard/dashboard_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OffersCarousel extends StatefulWidget {
  final bool isGuest;
  const OffersCarousel({super.key, this.isGuest = false});

  @override
  State<OffersCarousel> createState() => _OffersCarouselState();
}

class _OffersCarouselState extends State<OffersCarousel> {
  final PageController _pageController =
      PageController(viewportFraction: 1, initialPage: 1000);

  double _currentPage = 1000.0;
  Timer? _autoScrollTimer;
  Timer? _countdownTimer;
  Timer? _offersPollTimer;
  int _secondsLeft = 0;
  String _countdownLabel = 'Offer ends in';
  List<Content> _offersCache = const [];
  bool _isUserInteracting = false;

  @override
  void initState() {
    super.initState();

    if (!widget.isGuest) {
      context.read<RestaurantOffersCubit>().fetchRestaurantOffers();
      _offersPollTimer?.cancel();
      _offersPollTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
        if (!mounted) return;
        context.read<RestaurantOffersCubit>().fetchRestaurantOffers();
      });
    }

    _pageController.addListener(() {
      if (mounted) {
        setState(() {
          _currentPage = _pageController.page ?? _currentPage;
        });
      }
    });

    _startAutoScroll();
    _startCountdown();
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!_pageController.hasClients || _isUserInteracting) return;

      _pageController.nextPage(
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _countdownTimer?.cancel();
    _offersPollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isGuest) return _buildComingSoonCarousel();

    return BlocBuilder<RestaurantOffersCubit, RestaurantOffersState>(
      builder: (context, state) {
        if (state is RestaurantOffersLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is RestaurantOffersError) {
          return _buildComingSoonCarousel();
        } else if (state is RestaurantOffersLoaded) {
          final offers = state.offers.data?.content ?? [];
          _offersCache = offers;

          if (offers.isEmpty) return _buildComingSoonCarousel();

          return GestureDetector(
            onPanDown: (_) => _isUserInteracting = true,
            onPanCancel: () => _isUserInteracting = false,
            onPanEnd: (_) => _isUserInteracting = false,
            child: SizedBox(
              height: 180,
              child: Stack(
                children: [
                  PageView.builder(
                    controller: _pageController,
                    itemBuilder: (context, index) {
                      final Content offer = offers[index % offers.length];

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
                            onPressed: () async {
                              await context
                                  .read<ClearCartCubit>()
                                  .clearCart(context);

                              // Flag the special offer flow globally
                              final prefs =
                                  await SharedPreferences.getInstance();
                              await prefs.setBool('is_offer_flow', true);
                              await prefs.setString(
                                  'offer_id', (offer.id ?? '').toString());
                              await prefs.setString(
                                  'offer_coupon', offer.couponCode ?? '');
                              await prefs.setInt('offer_started_at',
                                  DateTime.now().millisecondsSinceEpoch);

                              if (!context.mounted) return;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DashboardScreen(
                                    couponCode: offer.couponCode,
                                  ),
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
                  Positioned(
                    right: 12,
                    top: 6,
                    child: _buildCountdownChip(),
                  ),
                ],
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  void _startCountdown() {
    _updateCountdown();
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _updateCountdown());
    });
  }

  void _updateCountdown() {
    if (_offersCache.isEmpty) {
      _secondsLeft = 0;
      _countdownLabel = 'Offer ends in';
      return;
    }

    final now = DateTime.now();
    final currentIndex = _currentPage.round();
    final offer = _offersCache[currentIndex % _offersCache.length];

    final slotStart = offer.slotStartTime;
    final slotEnd = offer.slotEndTime;
    DateTime? target;

    if (slotStart != null && now.isBefore(slotStart)) {
      _countdownLabel = 'Offer starts in';
      target = slotStart;
    } else if (slotEnd != null && now.isBefore(slotEnd)) {
      _countdownLabel = 'Offer ends in';
      target = slotEnd;
    } else {
      _countdownLabel = 'Offer ends in';
      target = offer.endDate;
    }

    if (target == null) {
      _secondsLeft = 0;
      return;
    }

    final seconds = target.difference(now).inSeconds;
    _secondsLeft = seconds < 0 ? 0 : seconds;
  }

  Widget _buildCountdownChip() {
    final m = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsLeft % 60).toString().padLeft(2, '0');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            '$_countdownLabel $m:$s',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildComingSoonCarousel() {
    final List<String> images = [
      // 'assets/images/jpg/lb_welcome.jpeg',
      'assets/images/jpg/COMING SOON.jpeg',
      'assets/images/jpg/PROMOTION.jpeg',
      // 'https://images.unsplash.com/photo-1525755662778-989d0524087e?auto=format&fit=crop&w=1200&q=80',
      // 'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?auto=format&fit=crop&w=1200&q=80',
    ];

    return SizedBox(
      height: 260,
      child: PageView.builder(
        controller: _pageController,
        itemBuilder: (context, index) {
          final image = images[index % images.length];
          final double scale = (_currentPage - index).abs() < 1.0
              ? 1 - (_currentPage - index).abs() * 0.1
              : 0.9;

          final bool isNetwork = image.startsWith("http");

          return Transform.scale(
            scale: scale,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                  image: isNetwork
                      ? NetworkImage(image)
                      : AssetImage(image) as ImageProvider,
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(isNetwork ? 0.4 : 0.0),
                      Colors.black.withOpacity(isNetwork ? 0.2 : 0.0),
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),

                // Show message only for network images
                child: isNetwork
                    ? const Center(
                        child: Text(
                          "Local Basket Coming Soon",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            shadows: [
                              Shadow(
                                blurRadius: 4,
                                color: Colors.black54,
                                offset: Offset(1, 2),
                              ),
                            ],
                          ),
                        ),
                      )
                    : const SizedBox(),
              ),
            ),
          );
        },
      ),
    );
  }

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
