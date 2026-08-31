import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:local_basket/core/constants/colors.dart';
import 'package:local_basket/core/utils/app_update_checker.dart';
import 'package:local_basket/core/utils/location_validator.dart';
import 'package:local_basket/core/utils/push_notication_services.dart';
import 'package:local_basket/data/model/cart/getCart/getCart_model.dart';
import 'package:local_basket/presentation/cubit/cart/clearCart/clearCart_cubit.dart';
import 'package:local_basket/presentation/cubit/cart/getCart/getCart_cubit.dart';
import 'package:local_basket/presentation/cubit/cart/getCart/getCart_state.dart';
import 'package:local_basket/presentation/cubit/notifications/fcmToken/fcm_token_cubit.dart';
import 'package:local_basket/presentation/cubit/restaurants/getNearbyRestaurants/getNearByrestarants_cubit.dart';
import 'package:local_basket/presentation/cubit/restaurants/getNearbyRestaurants/getNearByrestarants_state.dart';
import 'package:local_basket/presentation/cubit/restaurants/getRestaurantsByProductName/getRestaurantsByProductName_cubit.dart';
import 'package:local_basket/presentation/cubit/restaurants/getRestaurantsByProductName/getRestaurantsByProductName_state.dart';
import 'package:local_basket/presentation/screen/cart/cart_screen.dart';
import 'package:local_basket/presentation/screen/dashboard/main_dashboard_screen.dart';
import 'package:local_basket/presentation/screen/profile/profile_screen.dart';
import 'package:local_basket/presentation/screen/restaurantMenu/restaurantMenu_screen.dart';
import 'package:local_basket/presentation/screen/widgets/dashboard/LocationPermissionDialog.dart';
import 'package:local_basket/presentation/screen/widgets/dashboard/bottom_card_widget.dart';
import 'package:local_basket/presentation/screen/widgets/dashboard/clear_cart_dialog.dart';
import 'package:local_basket/presentation/screen/widgets/dashboard/foodItemCard.dart';
import 'package:local_basket/presentation/screen/widgets/dashboard/locationHeader.dart';
import 'package:local_basket/components/searchBar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

class DashboardScreen extends StatefulWidget {
  final String? couponCode;
  const DashboardScreen({super.key, this.couponCode});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  double? latitude;
  double? longitude;
  String searchQuery = '';
  List<CartItem> cartList = [];
  GetCartModel? cartData;
  final ScrollController _scrollController = ScrollController();
  final NotificationServices _notificationServices = NotificationServices();
  bool _showBottomCart = true;
  bool _isScrollingDown = false;
  double _scrollPosition = 0;
  int page = 0, size = 100;
  bool _showOffers = true;
  bool isLocationInitializing = true;
  late FocusNode _searchFocusNode;
  bool _isRequestingPermission = false;
  bool _isOutOfServiceArea = false;
  String _outOfServiceMessage = '';
  Timer? _storeStatusPollTimer;
  static const Duration _storeStatusPollInterval = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    _searchFocusNode = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await checkForAppUpdate(context);
      if (!mounted) return;
      debugPrint('🔄 Dashboard appeared → fetching stored FCM token');
      await context.read<FcmTokenCubit>().fetchFcmToken();
      await _requestNotificationPermission();
      await _fetchCart();
      await Future.delayed(const Duration(milliseconds: 1000));
      await _requestLocationPermission();
      await _maybeClearCartForOfferFlow();
    });

    _scrollController.addListener(_scrollListener);
  }

  Future<void> _requestNotificationPermission() async {
    // Ask for notification permission FIRST, then location permission
    // will be requested in _requestLocationPermission() right after.
    final token = await _notificationServices.getDeviceToken();
    debugPrint('🔔 Notification permission handled → FCM token: $token');

    if (token != null && token.isNotEmpty) {
      final deviceType = Platform.isAndroid ? 'ANDROID' : 'IOS';
      debugPrint('Storing FCM token via fcm-token API: $token');
      context.read<FcmTokenCubit>().storeFcmToken(
        fcmToken: token,
        deviceType: deviceType,
      );
    }
  }

  Future<void> _requestLocationPermission() async {
    if (_isRequestingPermission) return;
    _isRequestingPermission = true;

    setState(() => isLocationInitializing = true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      debugPrint("📍 Initial permission status: $permission");

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
        debugPrint("📍 After requestPermission: $permission");
      }

      if (!mounted) return;

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        debugPrint("✅ Permission granted → fetching coordinates");
        await _loadCoordinatesAndFetchRestaurants();
      } else {
        debugPrint("⚠️ Permission denied or forever denied → using fallback");

        final prefs = await SharedPreferences.getInstance();
        const fallbackLat = 17.385044;
        const fallbackLng = 78.486671;
        await prefs.setDouble('saved_latitude', fallbackLat);
        await prefs.setDouble('saved_longitude', fallbackLng);
        await _loadCoordinatesAndFetchRestaurants();
        await LocationPermissionDialog.show(context);
      }

      await _fetchCart();
    } catch (e) {
      debugPrint("❌ Location permission check failed: $e");
    } finally {
      if (mounted) {
        setState(() {
          isLocationInitializing = false;
        });
      }
      _isRequestingPermission = false;
    }
  }

  Future<void> _clearCart() async {
    await context
        .read<ClearCartCubit>()
        .clearCart(context, cartId: cartData?.id);
    await _fetchCart();
  }

  Future<void> _maybeClearCartForOfferFlow() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final couponFromParam = widget.couponCode;
      if (couponFromParam != null && couponFromParam.isNotEmpty) {
        await prefs.setBool('is_offer_flow', true);
        await prefs.setString('offer_coupon', couponFromParam);
        await prefs.setInt(
          'offer_started_at',
          DateTime.now().millisecondsSinceEpoch,
        );
      }

      final isOfferFlow = prefs.getBool('is_offer_flow') ?? false;

      if (!isOfferFlow) return;

      final cartCubit = context.read<GetCartCubit>();
      if (cartCubit.state is! GetCartLoaded) {
        await cartCubit.fetchCart(context);
      }

      final state = cartCubit.state;
      if (state is GetCartLoaded) {
        final hasItems = (state.cart.totalCount ?? 0) > 0;
        if (hasItems) {
          await context
              .read<ClearCartCubit>()
              .clearCart(context, cartId: state.cart.id);
          await cartCubit.fetchCart(context);
        }
      }
    } catch (_) {}
  }

  void _scrollListener() {
    final currentPosition = _scrollController.position.pixels;
    final scrollDelta = currentPosition - _scrollPosition;
    _scrollPosition = currentPosition;

    if (cartList.isNotEmpty && (cartData?.totalCount ?? 0) > 0) {
      if (scrollDelta > 10 && !_isScrollingDown) {
        _isScrollingDown = true;
        if (_showBottomCart) setState(() => _showBottomCart = false);
      } else if (scrollDelta < -10 && _isScrollingDown) {
        _isScrollingDown = false;
        if (!_showBottomCart) setState(() => _showBottomCart = true);
      }
    }

    if (scrollDelta > 10 && _showOffers) {
      setState(() => _showOffers = false);
    } else if (scrollDelta < -10 && !_showOffers) {
      setState(() => _showOffers = true);
    }
  }

  Future<void> _fetchCart() async {
    await context.read<GetCartCubit>().fetchCart(context);
    if (!mounted) return;

    final state = context.read<GetCartCubit>().state;
    if (state is GetCartLoaded) {
      if (!mounted) return;
      setState(() {
        cartList = state.cart.cartItems;
        cartData = state.cart;
        _showBottomCart =
            cartList.isNotEmpty && (cartData?.totalCount ?? 0) > 0;
      });
    }
  }

  void _onLocationChanged() {
    _loadCoordinatesAndFetchRestaurants();
  }

  Future<void> _refreshRestaurants() async {
    await _loadCoordinatesAndFetchRestaurants(forceRefresh: true);
  }

  Future<void> _loadCoordinatesAndFetchRestaurants({
    bool forceRefresh = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;

      setState(() {
        latitude = position.latitude;
        longitude = position.longitude;
      });

      await prefs.setDouble('saved_latitude', latitude!);
      await prefs.setDouble('saved_longitude', longitude!);

      _checkServiceArea(latitude!, longitude!);
    } catch (e) {
      debugPrint("⚠️ Failed to get current position: $e");

      final savedLat = prefs.getDouble('saved_latitude');
      final savedLng = prefs.getDouble('saved_longitude');

      if (!mounted) return;

      setState(() {
        latitude = savedLat;
        longitude = savedLng;
      });

      if (latitude == null || longitude == null) {
        debugPrint("❌ No valid coordinates found. Skipping fetch.");
        return;
      }

      _checkServiceArea(latitude!, longitude!);
    }
    if (!mounted) return;

    if (_isOutOfServiceArea) {
      return;
    }

    debugPrint(" Fetching restaurants with lat=$latitude, lon=$longitude");

    context
        .read<GetNearbyRestaurantsCubit>()
        .fetchNearbyRestaurants(_nearbyStoresParams(), forceRefresh: forceRefresh);

    _startStoreStatusPolling();
  }

  Map<String, dynamic> _nearbyStoresParams() {
    return {
      "latitude": latitude,
      "longitude": longitude,
      "radius": 5,
      "page": page,
      "size": size,
    };
  }

  // Periodically re-hits the nearby-stores API in the background so a
  // store's active/inactive status updates on screen without the user
  // having to pull-to-refresh.
  void _startStoreStatusPolling() {
    _storeStatusPollTimer?.cancel();
    _storeStatusPollTimer = Timer.periodic(_storeStatusPollInterval, (_) {
      if (!mounted || _isOutOfServiceArea || latitude == null || longitude == null) {
        return;
      }
      context
          .read<GetNearbyRestaurantsCubit>()
          .pollNearbyRestaurants(_nearbyStoresParams());
    });
  }

  void _stopStoreStatusPolling() {
    _storeStatusPollTimer?.cancel();
    _storeStatusPollTimer = null;
  }

  void _checkServiceArea(double lat, double lon) {
    final isWithinArea = LocationValidator.isWithinServiceArea(lat, lon);

    if (mounted) {
      setState(() {
        _isOutOfServiceArea = !isWithinArea;
        if (_isOutOfServiceArea) {
          _stopStoreStatusPolling();
          final distance = LocationValidator.calculateDistance(
            lat,
            lon,
            ANAKAPALLI_LATITUDE,
            ANAKAPALLI_LONGITUDE,
          );
          _outOfServiceMessage =
              'Service is currently available only within 5 km of Anakapalli.\n\nYou are ${distance.toStringAsFixed(1)} km away.';
        }
      });
    }
  }

  void _navigateToRestaurantMenu(
    String name,
    String id, {
    String? b2bUnitId,
  }) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => RestaurantMenuScreen(
              restaurantName: name,
              restaurantId: id,
              b2bUnitId: b2bUnitId,
              couponCode: widget.couponCode,
            ),
      ),
    );

    if (!mounted) return;
    _fetchCart();
  }

  Widget _buildRestaurantList<T>({
    required List<T> restaurants,
    required String Function(T) getName,
    required String Function(T) getCategory,
    required String Function(T) getId,
    String? Function(T)? getB2bUnitId,
    bool Function(T)? getActive,
    // required List<String> Function(T) getMediaList,
  }) {
    return Column(
      children:
          restaurants.map((restaurant) {
            return FoodItemCard(
              data: {
                "Restaurant": getName(restaurant),
                "Items": getCategory(restaurant),
                "time": "20 - 25 MINS",
              },
              isActive: getActive?.call(restaurant) ?? true,
              // mediaUrls: getMediaList(restaurant),
              onRestaurantTap:
                  (name) => _navigateToRestaurantMenu(
                    name,
                    getId(restaurant),
                    b2bUnitId: getB2bUnitId?.call(restaurant),
                  ),
            );
          }).toList(),
    );
  }

  String _formatDistance(double? distanceKm) {
    if (distanceKm == null) return '';
    return '${distanceKm.toStringAsFixed(2)} km away';
  }

  // Stores only take orders between 12 PM and 11 PM; outside that window
  // every store shows as inactive regardless of its own `active` flag.
  bool _isWithinStoreServiceHours() {
    final hour = DateTime.now().hour;
    return hour >= 12 && hour < 23;
  }

  Widget _buildNearbyRestaurants() {
    if (isLocationInitializing) {
      return _buildShimmerRestaurants();
    }

    return BlocBuilder<GetNearbyRestaurantsCubit, GetNearbyRestaurantsState>(
      builder: (context, state) {
        if (state is GetNearbyRestaurantsLoading) {
          return const Center(child: CupertinoActivityIndicator());
        } else if (state is GetNearbyRestaurantsLoaded) {
          if (state.model.content.isEmpty) {
            return const Center(child: Text("No restaurants found"));
          }
          return _buildRestaurantList(
            restaurants: state.model.content,
            getName: (r) => r.name ?? "Unknown",
            getCategory: (r) => _formatDistance(r.distanceKm),
            getId: (r) => (r.id ?? "").toString(),
            getB2bUnitId: (r) => r.b2bUnitId,
            getActive: (r) => (r.active ?? true) && _isWithinStoreServiceHours(),
          );
        } else {
          return const Center(child: Text("Failed loading restaurants"));
        }
      },
    );
  }

  Widget _buildSearchResults() {
    return BlocBuilder<
      GetRestaurantsByProductNameCubit,
      GetRestaurantsByProductNameState
    >(
      builder: (context, state) {
        if (state is GetRestaurantsByProductNameLoading) {
          return const Center(child: CupertinoActivityIndicator());
        } else if (state is GetRestaurantsByProductNameSuccess) {
          final query = searchQuery.trim().toLowerCase();
          final restaurants =
              state.model.content.where((store) {
                if (query.isEmpty) return true;
                return (store.name ?? '').toLowerCase().contains(query);
              }).toList();

          if (restaurants.isEmpty) {
            return const Center(child: Text("No restaurants found"));
          }

          return _buildRestaurantList(
            restaurants: restaurants,
            getName: (store) => store.name ?? "Unknown",
            getCategory: (store) => _formatDistance(store.distanceKm),
            getId: (store) => (store.id ?? "").toString(),
            getB2bUnitId: (store) => store.b2bUnitId,
            getActive: (store) => (store.active ?? true) && _isWithinStoreServiceHours(),
          );
        } else if (state is GetRestaurantsByProductNameFailure) {
          return Center(child: Text(state.error));
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildOutOfServiceWidget() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.orange.withOpacity(0.1),
              ),
              child: Icon(
                Icons.location_off_outlined,
                size: 60,
                color: AppColor.PrimaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Service Not Available',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColor.Black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _outOfServiceMessage,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: () {
                setState(() => isLocationInitializing = true);
                _loadCoordinatesAndFetchRestaurants();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.PrimaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Check Location Again',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '📍 Coming soon to your area!',
              style: TextStyle(
                fontSize: 12,
                color: AppColor.PrimaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    _stopStoreStatusPolling();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> safeSetState(VoidCallback fn) async {
    if (!_disposed && mounted) setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.White,
      body: RefreshIndicator(
        onRefresh: _refreshRestaurants,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // 🔻 Collapsible AppBar
            SliverAppBar(
              automaticallyImplyLeading: false,
              expandedHeight: 180,
              pinned: false,
              floating: false,
              backgroundColor: AppColor.PrimaryColor,
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.parallax,
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFF6B00), Color(0xFFFF1E00)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🔙 Top Row
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.arrow_back_ios,
                                  color: Colors.white,
                                ),
                                onPressed:
                                    () => Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => const MainDashboard(),
                                      ),
                                      (route) => false,
                                    ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child:
                                    (isLocationInitializing ||
                                            latitude == null ||
                                            longitude == null)
                                        ? Shimmer.fromColors(
                                          baseColor: Colors.grey.shade300,
                                          highlightColor: Colors.grey.shade100,
                                          child: Container(
                                            height: 20,
                                            width: 200,
                                            color: Colors.white,
                                          ),
                                        )
                                        : LocationHeader(
                                          key: ValueKey('$latitude$longitude'),
                                          latitude: latitude,
                                          longitude: longitude,
                                          onLocationChanged: _onLocationChanged,
                                        ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 26,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const ProfileScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        // 🔍 Search Bar
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: CategorySearchBar(
                            focusNode: _searchFocusNode,
                            hintText: "Search restaurants",
                            onChanged: (query) async {
                              if (_isOutOfServiceArea) return;
                              setState(() => searchQuery = query);
                              final prefs =
                                  await SharedPreferences.getInstance();
                              final lat =
                                  prefs.getDouble('saved_latitude') ??
                                  17.385044;
                              final lon =
                                  prefs.getDouble('saved_longitude') ??
                                  78.486671;
                              final params = {
                                "productName": query,
                                "latitude": lat,
                                "longitude": lon,
                                "radius": 5,
                                "page": 0,
                                "size": 10,
                              };
                              context
                                  .read<GetRestaurantsByProductNameCubit>()
                                  .fetchRestaurantsByProductName(params);
                            },
                          ),
                        ),
                        // if (!_isOutOfServiceArea)
                        //   Padding(
                        //     padding: const EdgeInsets.symmetric(horizontal: 16),
                        //     child: FoodCategoryIcons(
                        //       onCategoryTap: (label) async {
                        //         setState(() => searchQuery = label);
                        //         // Clear cache when searching to get fresh results
                        //         await _clearCache();
                        //         final prefs =
                        //             await SharedPreferences.getInstance();
                        //         final lat =
                        //             prefs.getDouble('saved_latitude') ??
                        //             17.385044;
                        //         final lon =
                        //             prefs.getDouble('saved_longitude') ??
                        //             78.486671;
                        //         final params = {
                        //           "productName": label,
                        //           "latitude": lat,
                        //           "longitude": lon,
                        //           "radius": 5,
                        //           "page": 0,
                        //           "size": 10,
                        //         };
                        //         context
                        //             .read<GetRestaurantsByProductNameCubit>()
                        //             .fetchRestaurantsByProductName(params);
                        //       },
                        //     ),
                        //   ),
                        // const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 🧾 Scrollable Content
            if (_isOutOfServiceArea)
              _buildOutOfServiceWidget()
            else
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        "Restaurants to Explore",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppColor.Black,
                        ),
                      ),
                      const SizedBox(height: 10),
                      searchQuery.isEmpty
                          ? _buildNearbyRestaurants()
                          : _buildSearchResults(),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),

            // ✅ Spacer for Bottom Cart
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
      bottomNavigationBar:
          (cartList.isNotEmpty && (cartData?.totalCount ?? 0) > 0)
              ? BottomCartCard(
                itemCount: cartData?.totalCount ?? 0,
                onDeletePressed: () {
                  showDialog(
                    context: context,
                    builder:
                        (context) => ClearCartDialog(
                          onClear: () async => await _clearCart(),
                        ),
                  );
                },
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => CartScreen(
                            cartItems:
                                cartList
                                    .map(
                                      (cartItem) => {
                                        'cartItemId': cartItem.id,
                                        'productId': cartItem.productId,
                                        'quantity': cartItem.quantity ?? 0,
                                        'price': cartItem.price ?? 0,
                                        'name': cartItem.productName ?? '',
                                        'media':
                                            cartItem.media.isNotEmpty
                                                ? cartItem.media[0].url
                                                : null,
                                      },
                                    )
                                    .toList(),
                          ),
                    ),
                  );
                  if (!mounted) return;
                  await _fetchCart();
                },
              )
              : null,
    );
  }

  Widget _buildShimmerRestaurants() {
    return Column(
      children: List.generate(4, (index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        );
      }),
    );
  }
}
