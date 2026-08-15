import 'dart:async';
import 'package:flutter/material.dart';
import 'package:local_basket/core/constants/colors.dart';
import 'package:local_basket/presentation/screen/profile/pool_screen.dart';

class OffersCarousel extends StatefulWidget {
  const OffersCarousel({super.key});

  @override
  State<OffersCarousel> createState() => _OffersCarouselState();
}

class _OffersCarouselState extends State<OffersCarousel> {
  final PageController _pageController = PageController(
    viewportFraction: 1,
    initialPage: 1000,
  );

  double _currentPage = 1000.0;
  Timer? _autoScrollTimer;
  bool _isUserInteracting = false;

  @override
  void initState() {
    super.initState();

    _pageController.addListener(() {
      if (mounted) {
        setState(() {
          _currentPage = _pageController.page ?? _currentPage;
        });
      }
    });

    _startAutoScroll();
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
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanDown: (_) => _isUserInteracting = true,
      onPanCancel: () => _isUserInteracting = false,
      onPanEnd: (_) => _isUserInteracting = false,
      child: _buildStaticCarousel(),
    );
  }

  Widget _buildStaticCarousel() {
    final List<String> images = [
      // 'assets/images/jpg/lb_welcome.jpeg',
      'assets/images/jpg/COMING SOON.jpeg',
      'assets/images/jpg/PROMOTION.jpeg',
      'assets/images/jpg/local_basket_ad.jpeg',
      'assets/images/jpg/promotion1.jpeg',
      // 'https://images.unsplash.com/photo-1525755662778-989d0524087e?auto=format&fit=crop&w=1200&q=80',
      // 'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?auto=format&fit=crop&w=1200&q=80',
    ];

    return SizedBox(
      height: 260,
      child: PageView.builder(
        controller: _pageController,
        itemBuilder: (context, index) {
          final image = images[index % images.length];
          final double scale =
              (_currentPage - index).abs() < 1.0
                  ? 1 - (_currentPage - index).abs() * 0.1
                  : 0.9;

          final bool isNetwork = image.startsWith("http");
          final bool isPromotion1 = image.contains('promotion1');

          void openPools() {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PoolScreen()),
            );
          }

          final Widget bannerBody = Stack(
            children: [
              Container(
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
                child:
                    isNetwork
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
              if (isPromotion1)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 18,
                  child: Center(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(30),
                        onTap: openPools,
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColor.PrimaryColor,
                                const Color(0xFFFF7A45),
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.white, width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: AppColor.PrimaryColor.withOpacity(0.5),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 26,
                              vertical: 12,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.celebration_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  "Participate Now",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );

          return Transform.scale(
            scale: scale,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                  image:
                      isNetwork
                          ? NetworkImage(image)
                          : AssetImage(image) as ImageProvider,
                  fit: BoxFit.contain,
                ),
              ),
              child:
                  isPromotion1
                      ? Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(onTap: openPools, child: bannerBody),
                      )
                      : bannerBody,
            ),
          );
        },
      ),
    );
  }
}
