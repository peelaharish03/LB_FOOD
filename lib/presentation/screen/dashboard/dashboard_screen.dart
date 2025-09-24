import 'package:local_basket/core/constants/colors.dart';
import 'package:local_basket/data/model/cart/getCart/getCart_model.dart';
import 'package:local_basket/presentation/cubit/cart/clearCart/clearCart_cubit.dart';
import 'package:local_basket/presentation/cubit/cart/createCart/createCart_cubit.dart';
import 'package:local_basket/presentation/cubit/cart/getCart/getCart_cubit.dart';
import 'package:local_basket/presentation/cubit/cart/getCart/getCart_state.dart';
import 'package:local_basket/presentation/cubit/offers/restaurant_offers/get_restaurant_offers/restaurant_offers_cubit.dart';
import 'package:local_basket/presentation/cubit/offers/restaurant_offers/get_restaurant_offers/restaurant_offers_state.dart';
import 'package:local_basket/presentation/cubit/restaurants/getNearbyRestaurants/getNearByrestarants_cubit.dart';
import 'package:local_basket/presentation/cubit/restaurants/getNearbyRestaurants/getNearByrestarants_state.dart';
import 'package:local_basket/presentation/cubit/restaurants/getRestaurantsByProductName/getRestaurantsByProductName_cubit.dart';
import 'package:local_basket/presentation/cubit/restaurants/getRestaurantsByProductName/getRestaurantsByProductName_state.dart';
import 'package:local_basket/presentation/cubit/restaurants/guestNearbyRestaurants/guestNearbyRestaurants_cubit.dart';
import 'package:local_basket/presentation/cubit/restaurants/guestNearbyRestaurants/guestNearbyRestaurants_state.dart';
import 'package:local_basket/presentation/screen/cart/cart_screen.dart';
import 'package:local_basket/presentation/screen/profile/profile_screen.dart';
import 'package:local_basket/presentation/screen/restaurantMenu/restaurantMenu_screen.dart';
import 'package:local_basket/presentation/screen/widgets/dashboard/LocationPermissionDialog.dart';
import 'package:local_basket/presentation/screen/widgets/dashboard/bottom_card_widget.dart';
import 'package:local_basket/presentation/screen/widgets/dashboard/clear_cart_dialog.dart';
import 'package:local_basket/presentation/screen/widgets/dashboard/foodCatagoryIcons.dart';
import 'package:local_basket/presentation/screen/widgets/dashboard/foodItemCard.dart';
import 'package:local_basket/presentation/screen/widgets/dashboard/locationHeader.dart';
import 'package:local_basket/components/searchBar.dart';
import 'package:local_basket/presentation/screen/widgets/dashboard/offersCard_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:local_basket/presentation/screen/widgets/loginPrompt.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

class DashboardScreen extends StatefulWidget {
  final bool isGuest;
  final String? couponCode;
  const DashboardScreen({super.key, this.isGuest = false,this.couponCode});

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
  int page = 0, size = 10;
  bool _showOffers = true;
  bool isLocationInitializing = true;
  late FocusNode _searchFocusNode;
  bool _isRequestingPermission = false;

  @override
  void initState() {
    super.initState();
    _searchFocusNode = FocusNode();
    context.read<CreateCartCubit>().createCart(context);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 1000));
      await _requestLocationPermission();
    });

    _scrollController.addListener(_scrollListener);
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

      if (!widget.isGuest) {
        await _fetchCart();
      }
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
    }
    if (!mounted) return;

    final params = {
      "latitude": latitude,
      "longitude": longitude,
      "postalCode": "531001",
      "page": page,
      "size": size,
      "searchTerm": ""
    };

    debugPrint("📍 Fetching restaurants with lat=$latitude, lon=$longitude");

    if (widget.isGuest) {
      context
          .read<GuestNearByRestaurantsCubit>()
          .fetchGuestNearbyRestaurants(params);
    } else {
      context.read<GetNearbyRestaurantsCubit>().fetchNearbyRestaurants(params);
    }
  }

  void _navigateToRestaurantMenu(String name, String id) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RestaurantMenuScreen(
          restaurantName: name,
          restaurantId: id,
          isGuest: widget.isGuest,
          couponCode : widget.couponCode
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
    required List<String> Function(T) getMediaList,
  }) {
    return Column(
      children: restaurants.map((restaurant) {
        return FoodItemCard(
          data: {
            "Restaurant": getName(restaurant),
            "Items": getCategory(restaurant),
            "mediaList": getMediaList(restaurant),
            // "itemPrice": "₹200",
            // "rating": 4.2,
            "time": "20 - 25 MINS"
          },
          mediaUrls: getMediaList(restaurant),
          onRestaurantTap: (name) =>
              _navigateToRestaurantMenu(name, getId(restaurant)),
        );
      }).toList(),
    );
  }

  Widget _buildNearbyRestaurants() {
    if (isLocationInitializing) {
      return _buildShimmerRestaurants();
    }
    return widget.isGuest
        ? BlocBuilder<GuestNearByRestaurantsCubit, GuestNearByRestaurantsState>(
            builder: (context, state) {
              if (state is GuestNearByRestaurantsLoading) {
                return const Center(child: CupertinoActivityIndicator());
              } else if (state is GuestNearByRestaurantsSuccess) {
                return _buildRestaurantList(
                  restaurants: state.data.content,
                  getName: (r) => r.businessName ?? "Unknown",
                  getCategory: (r) => r.categoryName ?? "",
                  getId: (r) => (r.id ?? "").toString(),
                  getMediaList: (r) =>
                      r.mediaList.map((e) => e.url ?? '').toList(),
                );
              } else {
                return const Center(
                    child: Text("Failed to load guest restaurants"));
              }
            },
          )
        : BlocBuilder<GetNearbyRestaurantsCubit, GetNearbyRestaurantsState>(
            builder: (context, state) {
              if (state is GetNearbyRestaurantsLoading) {
                return const Center(child: CupertinoActivityIndicator());
              } else if (state is GetNearbyRestaurantsLoaded) {
                return _buildRestaurantList(
                  restaurants: state.model.content,
                  getName: (r) => r.businessName ?? "Unknown",
                  getCategory: (r) => r.categoryName ?? "",
                  getId: (r) => (r.id ?? "").toString(),
                  getMediaList: (r) =>
                      r.mediaList.map((e) => e.url ?? '').toList(),
                );
              } else {
                return const Center(child: Text("Failed loading restaurants"));
              }
            },
          );
  }

  Widget _buildSearchResults() {
    if (widget.isGuest) {
      return BlocBuilder<GuestNearByRestaurantsCubit,
          GuestNearByRestaurantsState>(
        builder: (context, state) {
          if (state is GuestNearByRestaurantsLoading) {
            return const Center(child: CupertinoActivityIndicator());
          } else if (state is GuestNearByRestaurantsSuccess) {
            final filteredList = state.data.content;

            if (filteredList.isEmpty) {
              return const Center(child: Text("No restaurants found"));
            }

            return _buildRestaurantList(
              restaurants: filteredList,
              getName: (r) => r.businessName ?? "Unknown",
              getCategory: (r) => r.categoryName ?? "",
              getId: (r) => (r.id ?? "").toString(),
              getMediaList: (r) => r.mediaList.map((e) => e.url ?? '').toList(),
            );
          } else {
            return const Center(
                child: Text("Failed to load guest restaurants"));
          }
        },
      );
    } else {
      return BlocBuilder<GetRestaurantsByProductNameCubit,
          GetRestaurantsByProductNameState>(
        builder: (context, state) {
          if (state is GetRestaurantsByProductNameLoading) {
            return const Center(child: CupertinoActivityIndicator());
          } else if (state is GetRestaurantsByProductNameSuccess) {
            final contentList = state.model.content;

            if (contentList.isEmpty) {
              return const Center(child: Text("No restaurants found"));
            }

            final allProducts = contentList.expand((c) => c.products).toList();

            return _buildRestaurantList(
              restaurants: allProducts,
              getName: (p) => p.businessName ?? "Unknown",
              getCategory: (p) => p.categoryName ?? "",
              getId: (p) => (p.businessId ?? "").toString(),
              getMediaList: (p) => p.media.map((e) => e.url ?? '').toList(),
            );
          } else {
            return const SizedBox();
          }
        },
      );
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        if (_searchFocusNode.hasFocus) {
          _searchFocusNode.unfocus();
          return false;
        }
        return true;
      },
      child: BlocListener<GetCartCubit, GetCartState>(
        listener: (context, state) {
          if (state is GetCartLoaded) {
            setState(() {
              cartList = state.cart.cartItems;
              cartData = state.cart;
              _showBottomCart =
                  cartList.isNotEmpty && (cartData?.totalCount ?? 0) > 0;
            });
          }
          if (state is GetCartError) {}
        },
        child: Scaffold(
          backgroundColor: AppColor.White,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(330), // default max height
            child: ClipPath(
              child: Container(
                color: AppColor.PrimaryColor,
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Back Button
                            IconButton(
                              icon: const Icon(Icons.arrow_back_ios,
                                  color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                            const SizedBox(width: 8),

                            // Location (expanded in middle)
                            Expanded(
                              child: (isLocationInitializing ||
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
                                      isGuest: widget.isGuest,
                                    ),
                            ),

                            // Right-side Profile Icon
                            IconButton(
                              icon: const Icon(Icons.person,
                                  color: Colors.white, size: 26),
                              onPressed: () {
                                if (widget.isGuest) {
                                  showLoginPromptSheet(context);
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ProfileScreen(
                                          isGuest: widget.isGuest),
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),

                      // Search bar
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: CategorySearchBar(
                          focusNode: _searchFocusNode,
                          hintText:
                              "Search for restaurants, dishes, and cuisines",
                          onChanged: (query) async {
                            setState(() => searchQuery = query);

                            final prefs = await SharedPreferences.getInstance();
                            final lat =
                                prefs.getDouble('saved_latitude') ?? 17.385044;
                            final lon =
                                prefs.getDouble('saved_longitude') ?? 78.486671;

                            final params = {
                              "productName": query,
                              "latitude": lat,
                              "longitude": lon,
                              "postalCode": "531001",
                              "page": 0,
                              "size": 10,
                              "searchTerm": query,
                            };

                            if (widget.isGuest) {
                              context
                                  .read<GuestNearByRestaurantsCubit>()
                                  .fetchGuestNearbyRestaurants(params);
                            } else {
                              context
                                  .read<GetRestaurantsByProductNameCubit>()
                                  .fetchRestaurantsByProductName(params);
                            }
                          },
                        ),
                      ),

                      // BlocBuilder<RestaurantOffersCubit, RestaurantOffersState>(
                      //   builder: (context, state) {
                      //     if (state is RestaurantOffersLoaded &&
                      //         (state.offers.data?.content.isNotEmpty ??
                      //             false)) {
                      //       return const OffersCarousel();
                      //     }
                      //     return const SizedBox.shrink();
                      //   },
                      // ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          body: Stack(
            children: [
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        FoodCategoryIcons(
                          onCategoryTap: (label) async {
                            setState(() => searchQuery = label);

                            final prefs = await SharedPreferences.getInstance();
                            final lat =
                                prefs.getDouble('saved_latitude') ?? 17.385044;
                            final lon =
                                prefs.getDouble('saved_longitude') ?? 78.486671;

                            final params = {
                              "productName": label,
                              "latitude": lat,
                              "longitude": lon,
                              "postalCode": "531001",
                              "page": 0,
                              "size": 10,
                              "searchTerm": label, // relevant for guest cubit
                            };

                            if (widget.isGuest) {
                              context
                                  .read<GuestNearByRestaurantsCubit>()
                                  .fetchGuestNearbyRestaurants(params);
                            } else {
                              context
                                  .read<GetRestaurantsByProductNameCubit>()
                                  .fetchRestaurantsByProductName(params);
                            }
                          },
                        ),
                        const SizedBox(height: 10),
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
                        SizedBox(height: cartList.isNotEmpty ? 80 : 0),
                      ],
                    ),
                  ),
                ),
              ),
              if (cartList.isNotEmpty && (cartData?.totalCount ?? 0) > 0)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 300),
                    offset: _showBottomCart ? Offset.zero : const Offset(0, 1),
                    child: BottomCartCard(
                      itemCount: cartData?.totalCount ?? 0,
                      onDeletePressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => ClearCartDialog(
                            onClear: () async {
                              await _clearCart();
                            },
                          ),
                        );
                      },
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CartScreen(
                              cartItems: cartList
                                  .map((cartItem) => {
                                        'productId': cartItem.productId,
                                        'quantity': cartItem.quantity ?? 0,
                                        'price': cartItem.price ?? 0,
                                        'name': cartItem.productName ?? '',
                                        'media': cartItem.media.isNotEmpty
                                            ? cartItem.media[0].url
                                            : null,
                                      })
                                  .toList(),
                            ),
                          ),
                        );
                        if (!mounted) return;
                        if (result != null && result is Map) {
                          final updatedCount = result['cartItemsLength'] ?? 0;
                          final cubit = context.read<GetCartCubit>();
                          await cubit.fetchCart(context);
                          final state = cubit.state;
                          if (state is GetCartLoaded) {
                            setState(() {
                              cartList = state.cart.cartItems;
                              cartData = state.cart;
                              _showBottomCart = updatedCount > 0 &&
                                  (cartData?.totalCount ?? 0) > 0;
                            });
                            double total = 0;
                            debugPrint("🛒 Updated Cart Items:");
                            for (var item in cartList) {
                              final quantity = item.quantity ?? 0;
                              final price = item.price ?? 0;
                              final itemTotal = quantity * price;
                              total += itemTotal;
                              debugPrint(
                                  "→ ${item.productName}: Qty = $quantity, Price = ₹$price, Total = ₹$itemTotal");
                            }
                            debugPrint(
                                "🧾 Grand Total: ₹${total.toStringAsFixed(2)}");
                          }
                        }
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
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
