import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_basket/core/constants/colors.dart';
import 'package:local_basket/core/injection.dart';
import 'package:local_basket/data/model/pools/pools_model.dart';
import 'package:local_basket/presentation/cubit/pools/pools_cubit.dart';
import 'package:local_basket/presentation/cubit/pools/pools_state.dart';
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

  late final PoolsCubit _poolsCubit;

  double _currentPage = 1000.0;
  Timer? _autoScrollTimer;
  Timer? _clockTimer;
  bool _isUserInteracting = false;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();

    _poolsCubit = sl<PoolsCubit>()..fetchPools();

    _pageController.addListener(() {
      if (mounted) {
        setState(() {
          _currentPage = _pageController.page ?? _currentPage;
        });
      }
    });

    _startAutoScroll();

    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  bool _hasActivePool(PoolsState state) {
    if (state is! PoolsLoaded) return false;
    return state.pools.content.any(
      (pool) => (pool.apiStatus ?? pool.statusAt(_now)) == PoolStatus.active,
    );
  }

  /// The soonest upcoming pool, so the countdown always points at whichever
  /// pool will go live next.
  PoolItem? _nextUpcomingPool(PoolsState state) {
    if (state is! PoolsLoaded) return null;
    PoolItem? nearest;
    for (final pool in state.pools.content) {
      if ((pool.apiStatus ?? pool.statusAt(_now)) != PoolStatus.upcoming) {
        continue;
      }
      final start = pool.startDateTime;
      if (start == null) continue;
      if (nearest == null || start.isBefore(nearest.startDateTime!)) {
        nearest = pool;
      }
    }
    return nearest;
  }

  String _formatCountdown(Duration d) {
    if (d.isNegative) return '00:00:00';
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
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
    _clockTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _poolsCubit,
      child: GestureDetector(
        onPanDown: (_) => _isUserInteracting = true,
        onPanCancel: () => _isUserInteracting = false,
        onPanEnd: (_) => _isUserInteracting = false,
        child: BlocBuilder<PoolsCubit, PoolsState>(
          builder: (context, poolsState) {
            final hasActivePool = _hasActivePool(poolsState);
            final upcomingPool =
                hasActivePool ? null : _nextUpcomingPool(poolsState);
            return _buildStaticCarousel(hasActivePool, upcomingPool);
          },
        ),
      ),
    );
  }

  Widget _buildStaticCarousel(bool hasActivePool, PoolItem? upcomingPool) {
    final List<String> images = [
      // 'assets/images/jpg/lb_welcome.jpeg',
      // 'assets/images/jpg/COMING SOON.jpeg',
      'assets/images/jpg/slider1.jpeg',
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

          void openPools() {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PoolScreen()),
            );
          }

          final VoidCallback? onParticipateTap =
              hasActivePool ? openPools : null;

          final DateTime? upcomingStart = upcomingPool?.startDateTime;
          final String participateLabel =
              hasActivePool
                  ? "Try Your Luck 1rs Biriyani"
                  : upcomingStart != null
                  ? "Starts in ${_formatCountdown(upcomingStart.difference(_now))}"
                  : "No Active Offers";
          final IconData participateIcon =
              hasActivePool
                  ? Icons.celebration_rounded
                  : upcomingStart != null
                  ? Icons.timer_outlined
                  : Icons.hourglass_empty_rounded;

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
              Positioned(
                  left: 0,
                  right: 0,
                  bottom: 18,
                  child: Center(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(30),
                        onTap: onParticipateTap,
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient:
                                hasActivePool
                                    ? LinearGradient(
                                      colors: [
                                        AppColor.PrimaryColor,
                                        const Color(0xFFFF7A45),
                                      ],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    )
                                    : LinearGradient(
                                      colors: [
                                        Colors.grey.shade500,
                                        Colors.grey.shade400,
                                      ],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color:
                                  hasActivePool
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.6),
                              width: 1.5,
                            ),
                            boxShadow:
                                hasActivePool
                                    ? [
                                      BoxShadow(
                                        color: AppColor.PrimaryColor
                                            .withOpacity(0.5),
                                        blurRadius: 14,
                                        offset: const Offset(0, 6),
                                      ),
                                    ]
                                    : null,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 26,
                              vertical: 12,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  participateIcon,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  participateLabel,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                                if (hasActivePool) ...[
                                  const SizedBox(width: 6),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ],
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
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: InkWell(onTap: onParticipateTap, child: bannerBody),
              ),
            ),
          );
        },
      ),
    );
  }
}
