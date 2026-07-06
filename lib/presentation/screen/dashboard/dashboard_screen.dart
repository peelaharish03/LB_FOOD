import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:local_basket/core/constants/colors.dart';
import 'package:local_basket/data/model/cart/getCart/getCart_model.dart';
import 'package:local_basket/data/model/restaurants/getNearbyRestaurants/getNearByrestarants_model.dart';
import 'package:local_basket/presentation/cubit/cart/clearCart/clearCart_cubit.dart';
import 'package:local_basket/presentation/cubit/cart/getCart/getCart_cubit.dart';
import 'package:local_basket/presentation/cubit/cart/getCart/getCart_state.dart';
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
import 'package:local_basket/presentation/screen/widgets/dashboard/foodCatagoryIcons.dart';
import 'package:local_basket/presentation/screen/widgets/dashboard/foodItemCard.dart';
import 'package:local_basket/presentation/screen/widgets/dashboard/locationHeader.dart';
import 'package:local_basket/components/searchBar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

const double ANAKAPALLI_LATITUDE = 17.6869;
const double ANAKAPALLI_LONGITUDE = 82.8580;
const double SERVICE_RADIUS_KM = 40.0;

class LocationValidator {
  /// Calculate distance between two points using Haversine formula
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const R = 6371; // Earth radius in kilometers
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  static double _toRad(double degree) {
    return degree * math.pi / 180;
  }

  /// Check if location is within service radius
  static bool isWithinServiceArea(double latitude, double longitude) {
    final distance = calculateDistance(
      latitude,
      longitude,
      ANAKAPALLI_LATITUDE,
      ANAKAPALLI_LONGITUDE,
    );
    return distance <= SERVICE_RADIUS_KM;
  }
}

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
  bool _restaurantsLoaded = false;
  bool _isDataCached = false;
  List<Map<String, dynamic>>?
  _cachedRestaurants; // Store restaurant data as maps
  static const String _cacheTimestampKey = 'restaurants_cache_timestamp';
  static const String _cacheLatKey = 'restaurants_cache_lat';
  static const String _cacheLngKey = 'restaurants_cache_lng';
  static const String _cacheDataKey = 'restaurants_cache_data';
  static const Duration _cacheExpiry = Duration(hours: 1); // Cache for 1 hour

  @override
  void initState() {
    super.initState();
    _searchFocusNode = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _fetchCart();
      await Future.delayed(const Duration(milliseconds: 1000));
      await _requestLocationPermission();
      await _maybeClearCartForOfferFlow();
    });

    _scrollController.addListener(_scrollListener);

    // Check if we have cached data on init
    _checkCachedState();
  }

  Future<void> _checkCachedState() async {
    if (await _hasValidCache()) {
      setState(() {
        _restaurantsLoaded = true;
        _isDataCached = true;
      });
      debugPrint("📦 Restored cached state on init");
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
    await context.read<ClearCartCubit>().clearCart(context);
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
          await context.read<ClearCartCubit>().clearCart(context);
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
    _restaurantsLoaded = false;
    _isDataCached = false;
    _clearCache(); // Clear cache when location changes
    _loadCoordinatesAndFetchRestaurants();
  }

  Future<void> _refreshRestaurants() async {
    // Clear cache and force refresh
    await _clearCache();
    _restaurantsLoaded = false;
    _isDataCached = false;
    await _loadCoordinatesAndFetchRestaurants();
  }

  Future<void> _loadCoordinatesAndFetchRestaurants() async {
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

    // Check if we have cached data for the current location
    if (await _hasValidCache()) {
      debugPrint("📦 Using cached restaurant data - no API call");
      setState(() {
        _restaurantsLoaded = true;
        _isDataCached = true;
      });
      return; // Completely skip API calls
    }

    final params = {
      "latitude": latitude,
      "longitude": longitude,
      "radius": 5,
      "page": page,
      "size": size,
    };

    debugPrint(" Fetching restaurants with lat=$latitude, lon=$longitude");

    context.read<GetNearbyRestaurantsCubit>().fetchNearbyRestaurants(params);
  }

  // Cache management methods
  Future<bool> _hasValidCache() async {
    final prefs = await SharedPreferences.getInstance();

    final cachedTimestamp = prefs.getInt(_cacheTimestampKey);
    final cachedLat = prefs.getDouble(_cacheLatKey);
    final cachedLng = prefs.getDouble(_cacheLngKey);

    if (cachedTimestamp == null || cachedLat == null || cachedLng == null) {
      debugPrint("📦 No cache metadata found");
      return false;
    }

    // Check if cache is expired
    final now = DateTime.now().millisecondsSinceEpoch;
    final cacheAge = now - cachedTimestamp;
    if (cacheAge > _cacheExpiry.inMilliseconds) {
      debugPrint("📦 Cache expired");
      return false;
    }

    // Check if location has significantly changed (more than 1km)
    if (latitude != null && longitude != null) {
      final distance = LocationValidator.calculateDistance(
        latitude!,
        longitude!,
        cachedLat,
        cachedLng,
      );
      if (distance > 1.0) {
        // 1km threshold
        debugPrint("📦 Location changed significantly, invalidating cache");
        return false;
      }
    }

    // Load and validate cached restaurant data
    final cachedDataString = prefs.getString(_cacheDataKey);
    if (cachedDataString == null) {
      debugPrint("📦 No cached restaurant data found");
      return false;
    }

    try {
      final List<dynamic> decodedData = jsonDecode(cachedDataString);
      _cachedRestaurants = decodedData.cast<Map<String, dynamic>>();
      if (_cachedRestaurants == null || _cachedRestaurants!.isEmpty) {
        debugPrint("📦 Cached restaurant data is empty");
        return false;
      }
      debugPrint(
        "📦 Loaded ${_cachedRestaurants!.length} restaurants from cache",
      );
      return true;
    } catch (e) {
      debugPrint("📦 Failed to decode cached restaurant data: $e");
      return false;
    }
  }

  Future<void> _saveCache() async {
    final prefs = await SharedPreferences.getInstance();

    if (latitude != null && longitude != null) {
      await prefs.setInt(
        _cacheTimestampKey,
        DateTime.now().millisecondsSinceEpoch,
      );
      await prefs.setDouble(_cacheLatKey, latitude!);
      await prefs.setDouble(_cacheLngKey, longitude!);
      debugPrint("📦 Saved restaurant cache");
    }
  }

  Future<void> _saveRestaurantData(List<StoreContent> restaurants) async {
    final prefs = await SharedPreferences.getInstance();

    try {
      final restaurantJson =
          restaurants.map((r) {
            return {
              'id': r.id,
              'name': r.name,
              'code': r.code,
              'distanceKm': r.distanceKm,
              'latitude': r.latitude,
              'longitude': r.longitude,
            };
          }).toList();

      await prefs.setString(_cacheDataKey, jsonEncode(restaurantJson));
      _cachedRestaurants = restaurantJson.cast<Map<String, dynamic>>();
      debugPrint(
        "📦 Saved ${restaurantJson.length} restaurants to local storage",
      );
    } catch (e) {
      debugPrint("❌ Failed to save restaurant data: $e");
    }
  }

  Future<void> _clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheTimestampKey);
    await prefs.remove(_cacheLatKey);
    await prefs.remove(_cacheLngKey);
    await prefs.remove(_cacheDataKey);
    _cachedRestaurants = null;
    debugPrint("📦 Cleared restaurant cache");
  }

  void _checkServiceArea(double lat, double lon) {
    final isWithinArea = LocationValidator.isWithinServiceArea(lat, lon);

    if (mounted) {
      setState(() {
        _isOutOfServiceArea = !isWithinArea;
        if (_isOutOfServiceArea) {
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

  void _navigateToRestaurantMenu(String name, String id) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => RestaurantMenuScreen(
              restaurantName: name,
              restaurantId: id,
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
              // mediaUrls: getMediaList(restaurant),
              onRestaurantTap:
                  (name) => _navigateToRestaurantMenu(name, getId(restaurant)),
            );
          }).toList(),
    );
  }

  String _formatDistance(double? distanceKm) {
    if (distanceKm == null) return '';
    return '${distanceKm.toStringAsFixed(2)} km away';
  }

  Widget _buildCachedRestaurantList() {
    if (_cachedRestaurants == null || _cachedRestaurants!.isEmpty) {
      return const Center(child: Text("No cached restaurants available"));
    }

    return _buildRestaurantListFromMaps(_cachedRestaurants!);
  }

  Widget _buildRestaurantListFromMaps(List<Map<String, dynamic>> restaurants) {
    return Column(
      children:
          restaurants.map((restaurant) {
            return FoodItemCard(
              data: {
                "Restaurant": restaurant['name'] ?? "Unknown",
                "Items":
                    restaurant['distanceKm'] is num
                        ? _formatDistance(
                          (restaurant['distanceKm'] as num).toDouble(),
                        )
                        : "",
                "time": "20 - 25 MINS",
              },
              onRestaurantTap:
                  (name) => _navigateToRestaurantMenu(
                    name,
                    restaurant['id']?.toString() ?? "",
                  ),
            );
          }).toList(),
    );
  }

  Widget _buildNearbyRestaurants() {
    // If we have cached data, show it immediately without any loading
    if (_isDataCached &&
        _cachedRestaurants != null &&
        _cachedRestaurants!.isNotEmpty) {
      debugPrint("📦 Displaying cached restaurants - no loading");
      return _buildCachedRestaurantList();
    }

    if (isLocationInitializing) {
      return _buildShimmerRestaurants();
    }

    return BlocBuilder<GetNearbyRestaurantsCubit, GetNearbyRestaurantsState>(
      builder: (context, state) {
        if (state is GetNearbyRestaurantsLoading) {
          return const Center(child: CupertinoActivityIndicator());
        } else if (state is GetNearbyRestaurantsLoaded) {
          // Mark restaurants as loaded and save cache
          if (!_restaurantsLoaded) {
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              if (mounted) {
                setState(() {
                  _restaurantsLoaded = true;
                  _isDataCached = true;
                });
                await _saveCache();
                await _saveRestaurantData(state.model.content);
              }
            });
          }
          if (state.model.content.isEmpty) {
            return const Center(child: Text("No restaurants found"));
          }
          return _buildRestaurantList(
            restaurants: state.model.content,
            getName: (r) => r.name ?? "Unknown",
            getCategory: (r) => _formatDistance(r.distanceKm),
            getId: (r) => (r.id ?? "").toString(),
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
              expandedHeight: 260,
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
                              // Clear cache when searching to get fresh results
                              await _clearCache();
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
                        if (!_isOutOfServiceArea)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: FoodCategoryIcons(
                              onCategoryTap: (label) async {
                                setState(() => searchQuery = label);
                                // Clear cache when searching to get fresh results
                                await _clearCache();
                                final prefs =
                                    await SharedPreferences.getInstance();
                                final lat =
                                    prefs.getDouble('saved_latitude') ??
                                    17.385044;
                                final lon =
                                    prefs.getDouble('saved_longitude') ??
                                    78.486671;
                                final params = {
                                  "productName": label,
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
                        const SizedBox(height: 10),
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
