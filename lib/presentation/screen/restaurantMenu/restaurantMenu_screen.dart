import 'dart:async';
import 'dart:convert';
import 'package:local_basket/core/constants/restaurant_appbar.dart';
import 'package:local_basket/presentation/cubit/cart/getCart/getCart_cubit.dart';
import 'package:local_basket/presentation/cubit/cart/getCart/getCart_state.dart';
import 'package:local_basket/presentation/cubit/cart/productsAddToCart/productsAddtoCart_cubit.dart';
import 'package:local_basket/presentation/cubit/cart/clearCart/clearCart_cubit.dart';
import 'package:local_basket/presentation/screen/authentication/login_screen.dart';
import 'package:local_basket/presentation/screen/widgets/restaurantMenu/searchBar.dart';
import 'package:local_basket/presentation/screen/widgets/restaurantMenu/bottomSheet.dart';
import 'package:local_basket/presentation/screen/widgets/restaurantMenu/menu.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_basket/core/constants/colors.dart';
import 'package:local_basket/presentation/screen/cart/cart_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_basket/data/model/restaurants/guestMenuByRestaurantId/menu_content_model.dart';
import 'package:local_basket/presentation/cubit/restaurants/getMenuByRestaurantId/getMenuByRestaurantId_cubit.dart';
import 'package:local_basket/presentation/cubit/restaurants/getMenuByRestaurantId/getMenuByRestaurantId_state.dart';
import 'package:local_basket/presentation/cubit/restaurants/guestMenuByRestaurantId/guestMenuByRestaurantId_cubit.dart';
import 'package:local_basket/presentation/cubit/restaurants/guestMenuByRestaurantId/guestMenuByRestaurantId_state.dart';

class RestaurantMenuScreen extends StatefulWidget {
  final String restaurantName, restaurantId;
  final String? couponCode;
  final bool isGuest;
  const RestaurantMenuScreen({
    super.key,
    required this.restaurantName,
    required this.restaurantId,
    this.couponCode,
    this.isGuest = false,
  });

  @override
  _RestaurantMenuScreenState createState() => _RestaurantMenuScreenState();
}

class _RestaurantMenuScreenState extends State<RestaurantMenuScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  Map<String, int> cart = {};
  int totalItems = 0, page = 0, size = 20;
  PersistentBottomSheetController? _bottomSheetController;
  bool _isOfferFlow = false;
  bool isBottomSheetVisible = false;
  bool _showBackButton = true;
  String searchText = '', filterType = 'All';
  List<Content> selectedItems = [], menuItems = [];
  Timer? _debounce;
  bool _isMenuLoaded = false;
  bool _isCartLoaded = false;
  Content? _couponSelectedItem;
  bool _isLoadingMore = false;
  bool _isLastMenuPage = false;
  final ScrollController _scrollController = ScrollController();
  int _offerAutoLoadAttempts = 0;
  
  // Cache variables
  bool _isDataCached = false;
  List<Map<String, dynamic>>? _cachedMenuItems;
  static const String _menuCacheTimestampKey = 'menu_cache_timestamp';
  static const String _menuCacheRestaurantIdKey = 'menu_cache_restaurant_id';
  static const String _menuCacheDataKey = 'menu_cache_data';
  static const String _menuCacheUserTypeKey = 'menu_cache_user_type';
  static const Duration _menuCacheExpiry = Duration(hours: 1); // Cache for 1 hour

  @override
  void initState() {
    super.initState();

    print("RestaurantMenuScreen - isGuest: ${widget.isGuest}");

    WidgetsBinding.instance.addPostFrameCallback((_) {
      () async {
        final prefs = await SharedPreferences.getInstance();
        final hasCoupon = (widget.couponCode?.isNotEmpty ?? false);
        final stickyOffer = prefs.getBool('is_offer_flow') ?? false;

        if (!hasCoupon && stickyOffer) {
          await prefs.remove('is_offer_flow');
        }

        if (mounted) setState(() => _isOfferFlow = hasCoupon);
      }();

      // Check for cached menu data first
      _checkCachedMenuData();

      if (!widget.isGuest) {
        _scrollController.addListener(() {
          final direction = _scrollController.position.userScrollDirection;
          if (direction == ScrollDirection.reverse) {
            if (_showBackButton) {
              setState(() => _showBackButton = false);
            }
          } else if (direction == ScrollDirection.forward) {
            if (!_showBackButton) {
              setState(() => _showBackButton = true);
            }
          }
          if (_scrollController.position.extentAfter < 300) {
            _loadMoreMenu();
          }
        });
      }
    });
  }

  void _showReplaceItemDialog(Content newItem) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text("Replace item?"),
        content: const Text(
            "You can only select one item with this coupon. Do you want to replace your current item with the new one?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.PrimaryColor,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();

              cart.clear();
              selectedItems.clear();
              totalItems = 0;

              _couponSelectedItem = newItem;
              await update_Cart(newItem, 1);
            },
            child: const Text("Replace"),
          )
        ],
      ),
    );
  }

  Future<void> _loadCart() async {
    final cartState = context.read<GetCartCubit>().state;
    if (cartState is GetCartLoaded) {
      _processCartData(cartState);
    } else {
      await Future.delayed(const Duration(milliseconds: 100));
      final newCartState = context.read<GetCartCubit>().state;
      if (newCartState is GetCartLoaded) {
        _processCartData(newCartState);
      }
    }
  }

  void _processCartData(GetCartLoaded state) {
    if (state.cart.businessId.toString() != widget.restaurantId) return;
    if (!_isMenuLoaded) return;

    int itemCounter = 0;
    Map<String, int> updatedCart = {};
    List<Content> updatedSelectedItems = [];

    for (var cartItem in state.cart.cartItems) {
      final menuItem = menuItems.firstWhere(
        (item) => item.id == cartItem.productId,
        orElse: () => Content(
          id: 0,
          name: '',
          shortCode: '',
          ignoreTax: false,
          discount: true,
          description: '',
          price: 0,
          available: false,
          shopifyProductId: '',
          shopifyVariantId: '',
          businessId: 0,
          categoryId: 0,
          media: [],
          attributes: [],
        ),
      );

      if (menuItem.id != 0) {
        final qty = cartItem.quantity ?? 0;
        updatedCart[menuItem.name ?? ""] = qty;
        updatedSelectedItems.add(menuItem);
        itemCounter += qty;
      }
    }

    if (!mounted) return;
    setState(() {
      cart = updatedCart;
      selectedItems = updatedSelectedItems;
      totalItems = itemCounter;
      _isCartLoaded = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (totalItems > 0 && !isBottomSheetVisible) {
        showPersistentCart();
      } else if (totalItems == 0 && isBottomSheetVisible) {
        _bottomSheetController?.close();
      }
    });
  }

  Future<void> _loadMenu() async {
    print('Loading menu with search: "$searchText", filterType: "$filterType"');
    page = 0;
    _isLastMenuPage = false;
    _isLoadingMore = false;
    menuItems = [];
    _offerAutoLoadAttempts = 0;
    
    // Check if we have cached data first
    if (await _hasValidMenuCache()) {
      print('📦 Using cached menu data - no API call');
      return;
    }
    
    await context.read<GetMenuByRestaurantIdCubit>().fetchMenu({
      'restaurantId': widget.restaurantId,
      'search': searchText,
      'page': page,
      'size': size,
    });
  }

  bool _matchesOfferBiryani(Content item) {
    final name = (item.name ?? '').toLowerCase();
    final desc = (item.description ?? '').toLowerCase();
    final text = '$name $desc';
    return text.contains('biryani') || text.contains('biriyani');
  }

  void _maybeAutoloadOfferPages() {
    if (!_isOfferFlow || !(widget.couponCode?.isNotEmpty ?? false)) return;
    if (_isLastMenuPage) return;
    if (_isLoadingMore) return;
    if (_offerAutoLoadAttempts >= 6) return;

    final hasAnyBiryani = menuItems.any(_matchesOfferBiryani);
    if (!hasAnyBiryani) {
      _offerAutoLoadAttempts += 1;
      _loadMoreMenu();
    }
  }

  Future<void> _loadMoreMenu() async {
    if (widget.isGuest) return;
    if (_isLastMenuPage) return;
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);
    page = page + 1;
    await context.read<GetMenuByRestaurantIdCubit>().fetchMenu({
      'restaurantId': widget.restaurantId,
      'search': searchText,
      'page': page,
      'size': size,
    });
  }

  // Cache management methods
  Future<void> _checkCachedMenuData() async {
    if (await _hasValidMenuCache()) {
      print('📦 Loading menu from cache');
      await _loadMenuFromCache();
      
      // Load cart after menu is loaded from cache
      if (!widget.isGuest) {
        Future.delayed(const Duration(milliseconds: 300), () {
          _loadCart();
        });
      }
    } else {
      // No valid cache, load from API
      if (widget.isGuest) {
        context
            .read<GuestMenuByRestaurantIdCubit>()
            .fetchGuestMenuByRestaurantId({
          'restaurantId': int.tryParse(widget.restaurantId) ?? 0,
        });
      } else {
        context.read<GetMenuByRestaurantIdCubit>().fetchMenu({
          'restaurantId': widget.restaurantId,
          'search': searchText,
          'page': page,
          'size': size,
        });
        Future.delayed(const Duration(milliseconds: 300), () {
          _loadCart();
        });
      }
    }
  }

  Future<bool> _hasValidMenuCache() async {
    final prefs = await SharedPreferences.getInstance();
    
    final cachedTimestamp = prefs.getInt(_menuCacheTimestampKey);
    final cachedRestaurantId = prefs.getString(_menuCacheRestaurantIdKey);
    final cachedUserType = prefs.getString(_menuCacheUserTypeKey);
    
    if (cachedTimestamp == null || cachedRestaurantId == null || cachedUserType == null) {
      print('📦 No menu cache metadata found');
      return false;
    }
    
    // Check if restaurant ID matches
    if (cachedRestaurantId != widget.restaurantId) {
      print('📦 Restaurant ID changed, invalidating menu cache');
      return false;
    }
    
    // Check if user type matches
    final currentUserType = widget.isGuest ? 'guest' : 'user';
    if (cachedUserType != currentUserType) {
      print('📦 User type changed, invalidating menu cache');
      return false;
    }
    
    // Check if cache is expired
    final now = DateTime.now().millisecondsSinceEpoch;
    final cacheAge = now - cachedTimestamp;
    if (cacheAge > _menuCacheExpiry.inMilliseconds) {
      print('📦 Menu cache expired');
      return false;
    }
    
    // Load and validate cached menu data
    final cachedDataString = prefs.getString(_menuCacheDataKey);
    if (cachedDataString == null) {
      print('📦 No cached menu data found');
      return false;
    }
    
    try {
      final List<dynamic> decodedData = jsonDecode(cachedDataString);
      _cachedMenuItems = decodedData.cast<Map<String, dynamic>>();
      if (_cachedMenuItems == null || _cachedMenuItems!.isEmpty) {
        print('📦 Cached menu data is empty');
        return false;
      }
      print('📦 Loaded ${_cachedMenuItems!.length} menu items from cache');
      return true;
    } catch (e) {
      print('📦 Failed to decode cached menu data: $e');
      return false;
    }
  }

  Future<void> _loadMenuFromCache() async {
    if (_cachedMenuItems == null) return;
    
    // Convert cached maps back to Content objects
    menuItems = _cachedMenuItems!.map((item) => Content(
      id: item['id'] ?? 0,
      name: item['name'] ?? '',
      shortCode: item['shortCode'] ?? '',
      ignoreTax: item['ignoreTax'] ?? false,
      discount: item['discount'] ?? true,
      description: item['description'] ?? '',
      price: (item['price'] ?? 0).toDouble(),
      available: item['available'] ?? false,
      shopifyProductId: item['shopifyProductId'] ?? '',
      shopifyVariantId: item['shopifyVariantId'] ?? '',
      businessId: item['businessId'] ?? 0,
      categoryId: item['categoryId'] ?? 0,
      media: (item['media'] as List<dynamic>?)?.map((m) => Media(
        mediaType: m['mediaType'] ?? '',
        url: m['url'] ?? '',
      )).toList() ?? [],
      attributes: (item['attributes'] as List<dynamic>?)?.map((a) => Attribute(
        id: a['id'] ?? 0,
        attributeName: a['attributeName'] ?? '',
        attributeValue: a['attributeValue'] ?? '',
      )).toList() ?? [],
    )).toList();
    
    setState(() {
      _isMenuLoaded = true;
      _isDataCached = true;
    });
  }

  Future<void> _saveMenuToCache(List<Content> menuData) async {
    final prefs = await SharedPreferences.getInstance();
    
    try {
      // Convert menu items to JSON for storage
      final menuJson = menuData.map((item) => {
        'id': item.id,
        'name': item.name,
        'shortCode': item.shortCode,
        'ignoreTax': item.ignoreTax,
        'discount': item.discount,
        'description': item.description,
        'price': item.price,
        'available': item.available,
        'shopifyProductId': item.shopifyProductId,
        'shopifyVariantId': item.shopifyVariantId,
        'businessId': item.businessId,
        'categoryId': item.categoryId,
        'media': item.media?.map((m) => {
          'mediaType': m.mediaType,
          'url': m.url,
        }).toList() ?? [],
        'attributes': item.attributes?.map((a) => {
          'id': a.id,
          'attributeName': a.attributeName,
          'attributeValue': a.attributeValue,
        }).toList() ?? [],
      }).toList();
      
      await prefs.setString(_menuCacheDataKey, jsonEncode(menuJson));
      await prefs.setInt(_menuCacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
      await prefs.setString(_menuCacheRestaurantIdKey, widget.restaurantId);
      await prefs.setString(_menuCacheUserTypeKey, widget.isGuest ? 'guest' : 'user');
      
      _cachedMenuItems = menuJson.cast<Map<String, dynamic>>();
      print('📦 Saved ${menuJson.length} menu items to cache');
    } catch (e) {
      print('❌ Failed to save menu data: $e');
    }
  }

  Future<void> _clearMenuCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_menuCacheTimestampKey);
    await prefs.remove(_menuCacheRestaurantIdKey);
    await prefs.remove(_menuCacheDataKey);
    await prefs.remove(_menuCacheUserTypeKey);
    _cachedMenuItems = null;
    print('📦 Cleared menu cache');
  }

  Future<void> update_Cart(Content item, int qty) async {
    if (_isOfferFlow) {
      if (_couponSelectedItem != null && _couponSelectedItem!.id != item.id) {}

      if (qty == 0) {
        await context.read<ClearCartCubit>().clearCart(context);
        await context.read<GetCartCubit>().fetchCart(context);
        if (!mounted) return;
        setState(() {
          cart.clear();
          selectedItems.clear();
          totalItems = 0;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (isBottomSheetVisible) {
            _bottomSheetController?.close();
            _onBottomSheetVisibilityChanged(false);
          }
        });
        return;
      }

      final existingState = context.read<GetCartCubit>().state;
      if (existingState is GetCartLoaded &&
          (existingState.cart.totalCount ?? 0) > 0) {
        await context.read<ClearCartCubit>().clearCart(context);
      }

      cart = {item.name ?? "": 1};
      selectedItems = [item];

      menuItems = List.from(menuItems);

      totalItems = 1;

      setState(() {});
      final List<Map<String, dynamic>> items = [
        {"productId": item.id, "quantity": 1}
      ];

      final cartState = context.read<GetCartCubit>().state;
      String notes = "";
      bool selfOrder = false;
      if (cartState is GetCartLoaded) {
        notes = cartState.cart.notes ?? "";
        selfOrder = false;
      }

      final Map<String, dynamic> payload = {
        "notes": notes,
        "selfOrder": selfOrder,
        "isOffer": _isOfferFlow && (widget.couponCode?.isNotEmpty ?? false),
        "items": items,
      };
      await context.read<ProductsAddToCartCubit>().addToCart(payload);
      await context.read<GetCartCubit>().fetchCart(context);

      // Ensure bottom cart sheet reflects the new selection immediately
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (totalItems > 0 && !isBottomSheetVisible) {
          showPersistentCart();
        } else if (totalItems == 0 && isBottomSheetVisible) {
          _bottomSheetController?.close();
        } else if (isBottomSheetVisible) {
          _bottomSheetController?.setState?.call(() {});
        }
      });

      return;
    }

    // ------------------ Normal Flow ------------------
    var updatedCart = Map<String, int>.from(cart);
    var updatedSelectedItems = List<Content>.from(selectedItems);

    if (qty == 0) {
      updatedCart.remove(item.name);
      updatedSelectedItems.removeWhere((i) => i.name == item.name);
      context.read<GetCartCubit>().fetchCart(context);
    } else {
      updatedCart[item.name ?? ""] = qty;
      if (!updatedSelectedItems.any((i) => i.name == item.name)) {
        updatedSelectedItems.add(item);
      }
    }

    int newTotalItems = updatedCart.values.fold(0, (sum, qty) => sum + qty);

    if (!mounted) return;
    setState(() {
      cart = updatedCart;
      selectedItems = updatedSelectedItems;
      totalItems = newTotalItems;
      final idx = menuItems.indexWhere((m) => m.name == item.name);
      if (idx != -1) menuItems[idx] = item;
    });

    final List<Map<String, dynamic>> items = selectedItems
        .map((itm) => {
              "productId": itm.id,
              "quantity": cart[itm.name] ?? 0,
            })
        .toList();

    final cartState = context.read<GetCartCubit>().state;
    String notes = "";
    bool selfOrder = false;

    if (cartState is GetCartLoaded) {
      notes = cartState.cart.notes ?? "";
      selfOrder = false;
    }

    final Map<String, dynamic> payload = {
      "notes": notes,
      "selfOrder": selfOrder,
      "isOffer": _isOfferFlow && (widget.couponCode?.isNotEmpty ?? false),
      "items": items,
    };

    debugPrint('ProductsAddToCart Payload: $payload');
    context.read<ProductsAddToCartCubit>().addToCart(payload);
    context.read<GetCartCubit>().fetchCart(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (totalItems > 0 && !isBottomSheetVisible) {
        showPersistentCart();
      } else if (totalItems == 0 && isBottomSheetVisible) {
        _bottomSheetController?.close();
      } else if (isBottomSheetVisible) {
        _bottomSheetController?.setState?.call(() {});
      }
    });
  }

  void showPersistentCart() {
    final rootContext = context;
    _bottomSheetController =
        _scaffoldKey.currentState!.showBottomSheet((bottomSheetContext) {
      return RestaurantCartBottomSheet(
        totalItems: totalItems,
        onViewCartPressed: () async {
          _bottomSheetController?.close();
          final result = await Navigator.push(
            rootContext,
            MaterialPageRoute(
              builder: (_) => CartScreen(
                cartItems: selectedItems.map((item) {
                  final onlinePriceAttr = item.attributes.firstWhere(
                    (attr) =>
                        attr.attributeName?.toLowerCase() == 'onlineprice',
                    orElse: () => Attribute(
                      id: null,
                      attributeName: null,
                      attributeValue: null,
                    ),
                  );
                  final effectivePrice = onlinePriceAttr.attributeValue != null
                      ? double.tryParse(onlinePriceAttr.attributeValue!) ??
                          (item.price ?? 0)
                      : item.price ?? 0;

                  return {
                    'productId': item.id,
                    'quantity': cart[item.name] ?? 0,
                    'price': effectivePrice,
                    'name': item.name,
                    'description': item.description,
                    'categoryName': item.attributes
                        .firstWhere(
                          (a) => a.attributeName?.toLowerCase() == 'type',
                          orElse: () => Attribute(
                            id: 0,
                            attributeName: '',
                            attributeValue: '',
                          ),
                        )
                        .attributeValue,
                    'media': item.media,
                  };
                }).toList(),
                onBottomSheetVisibilityChanged: _onBottomSheetVisibilityChanged,
              ),
            ),
          );

          if (!mounted) return;

          if (result != null && result is Map<String, dynamic>) {
            final updatedCart = result['updatedCart'] as Map<int, int>?;
            final updatedCartLength = result['cartItemsLength'] ?? 0;

            if (updatedCart != null) {
              setState(() {
                cart.clear();
                selectedItems.clear();

                for (var entry in updatedCart.entries) {
                  final productId = entry.key;
                  final quantity = entry.value;

                  final item = menuItems.firstWhere(
                    (item) => item.id == productId,
                    orElse: () => Content(
                      id: 0,
                      name: '',
                      shortCode: '',
                      ignoreTax: false,
                      discount: true,
                      description: '',
                      price: 0,
                      available: false,
                      shopifyProductId: '',
                      shopifyVariantId: '',
                      businessId: 0,
                      categoryId: 0,
                      media: [],
                      attributes: [],
                    ),
                  );

                  if (item.id != 0) {
                    cart[item.name ?? ""] = quantity;
                    selectedItems.add(item);
                  }
                }

                totalItems = updatedCartLength;
              });

              _onBottomSheetVisibilityChanged(false);
              await Future.delayed(const Duration(milliseconds: 100));

              if (mounted && cart.isNotEmpty) {
                showPersistentCart();
              }

              if (!widget.isGuest) {
                // Refresh cart from backend to ensure full consistency
                await rootContext.read<GetCartCubit>().fetchCart(rootContext);
                _loadMenu();
              }
            }
          }
        },
      );
    });

    _bottomSheetController!.closed.then((_) {
      if (!mounted) return;
      setState(() {
        isBottomSheetVisible = false;
      });
    });

    setState(() {
      isBottomSheetVisible = true;
    });
  }

  void _onBottomSheetVisibilityChanged(bool visible) {
    if (!mounted) return;
    setState(() {
      isBottomSheetVisible = visible;
    });

    if (!visible && totalItems == 0) {
      _bottomSheetController?.close();
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query != searchText) {
        setState(() => searchText = query);
        // Clear cache when searching to get fresh results
        await _clearMenuCache();
        await _loadMenu();
      }
    });
  }

  void showLoginPromptBottomSheet(BuildContext context, int qty, Content item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock, size: 40, color: AppColor.PrimaryColor),
              const SizedBox(height: 12),
              Text(
                "Login Required",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Please login to add items to your cart.",
                textAlign: TextAlign.center,
                style:
                    GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        setState(() {
                          cart[item.name ?? ""] = qty;
                          selectedItems.add(item);
                          totalItems += qty;
                        });
                      },
                      child: const Text("Cancel"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.PrimaryColor,
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(context,
                            MaterialPageRoute(builder: (_) => LoginScreen()));
                      },
                      child: const Text("Login"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _bottomSheetController?.close();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) async {
        if (!didPop && isBottomSheetVisible && _bottomSheetController != null) {
          _bottomSheetController?.close();
          await Future.delayed(const Duration(milliseconds: 300));
          if (mounted) Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.grey[100],
        body: Stack(
          children: [
            SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.only(
                top: 300,
                bottom: 100,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: HomeSearchBar(
                      hintText: "menu",
                      onChanged: _onSearchChanged,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Filter Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: ['All', 'Veg', 'NonVeg'].map((filter) {
                        final isSelected = filter == filterType;
                        Widget? icon;
                        if (filter == 'Veg') icon = vegNonVegIcon(true);
                        if (filter == 'NonVeg') icon = vegNonVegIcon(false);

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () async {
                              setState(() {
                                filterType = filter;
                              });
                              // Clear cache when filter changes to get fresh results
                              await _clearMenuCache();
                              if (!widget.isGuest) _loadMenu();
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColor.PrimaryColor
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColor.PrimaryColor
                                      : Colors.grey.shade300,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color:
                                              AppColor.PrimaryColor.withAlpha(
                                                  50),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        )
                                      ]
                                    : [],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (icon != null) ...[
                                    icon,
                                    const SizedBox(width: 6),
                                  ],
                                  Text(
                                    filter,
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Menu Items
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: widget.isGuest
                        ? _buildGuestMenuItems()
                        : _buildUserMenuItems(),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SwiggyStyleAppBar(
                restaurantName: widget.restaurantName,
                location: "Anakapalle",
                deliveryTime: "20–25 mins",
                rating: 4.4,
                offerText: "Items at ₹109 on select items",
                isBottomSheetVisible: isBottomSheetVisible,
                bottomSheetController: _bottomSheetController,
                selectedItems: selectedItems,
                cart: cart,
                totalItems: totalItems,
                showBackButton: _showBackButton,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCachedMenuItems() {
    if (menuItems.isEmpty) {
      return const Center(child: Text("No cached menu items available"));
    }

    // Apply the same filtering logic as the original BLoC builders
    final filteredItems = menuItems.where((item) {
      if (_isOfferFlow && (widget.couponCode?.isNotEmpty ?? false)) {
        if (!_matchesOfferBiryani(item)) return false;
      }
      final matchesSearch = (item.name ?? "")
          .toLowerCase()
          .contains(searchText.toLowerCase());
      final foodType = item.attributes
          .firstWhere(
            (a) => (a.attributeName ?? "").toLowerCase() == 'type',
            orElse: () => Attribute(
              id: 0,
              attributeName: 'type',
              attributeValue: 'unknown',
            ),
          )
          .attributeValue ??
          'unknown';
      final matchesFilter = filterType == 'All' ||
          (filterType == 'Veg' && foodType.toLowerCase() == 'veg') ||
          (filterType == 'NonVeg' && foodType.toLowerCase() == 'nonveg');
      return matchesSearch && matchesFilter;
    }).toList();

    return Column(
      children: [
        ...filteredItems.map((item) {
          final qty = cart[item.name ?? ""] ?? 0;
          return MenuItemWidget(
            item: item,
            quantity: qty,
            restaurantId: widget.restaurantId,
            restaurantName: widget.restaurantName,
            isCouponFlow: _isOfferFlow,
            onQuantityChanged: (newQty) async {
              if (_isOfferFlow) {
                final alreadySelected = cart.entries.any((entry) =>
                    entry.value > 0 && entry.key != item.name);
                if (alreadySelected && newQty > 0) {
                  _showReplaceItemDialog(item);
                  return;
                }
              }
              await update_Cart(item, newQty);
            },
          );
        }),
        if (_isLoadingMore)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: CupertinoActivityIndicator(),
          ),
      ],
    );
  }

  Widget _buildGuestMenuItems() {
    // If we have cached data, show it immediately without any loading
    if (_isDataCached && _cachedMenuItems != null && _cachedMenuItems!.isNotEmpty) {
      print('📦 Displaying cached guest menu items - no loading');
      return _buildCachedMenuItems();
    }
    
    return BlocConsumer<GuestMenuByRestaurantIdCubit,
        GuestMenuByRestaurantIdState>(
      listener: (context, state) {
        if (state is GuestMenuByRestaurantIdSuccess) {
          _isMenuLoaded = true;
          // Save menu data to cache
          _saveMenuToCache(state.data.content);
        }
      },
      builder: (context, state) {
        if (state is GuestMenuByRestaurantIdLoading) {
          return const Center(child: CupertinoActivityIndicator());
        } else if (state is GuestMenuByRestaurantIdSuccess) {
          final filteredItems = state.data.content.where((item) {
            final matchesSearch = (item.name ?? "")
                .toLowerCase()
                .contains(searchText.toLowerCase());

            final foodType = item.attributes
                .firstWhere(
                  (a) => (a.attributeName ?? "").toLowerCase() == 'type',
                  orElse: () =>
                      Attribute(id: 0, attributeName: '', attributeValue: ''),
                )
                .attributeValue
                ?.toLowerCase();

            final matchesFilter = filterType == 'All' ||
                (filterType.toLowerCase() == 'veg' && foodType == 'veg') ||
                (filterType.toLowerCase() == 'nonveg' && foodType == 'nonveg');

            return matchesSearch && matchesFilter;
          }).toList();

          if (filteredItems.isEmpty) {
            return const Center(child: Text("No menu items available"));
          }

          return Column(
            children: filteredItems.map((item) {
              return MenuItemWidget(
                item: item,
                quantity: 0,
                restaurantId: widget.restaurantId,
                restaurantName: widget.restaurantName,
                isGuest: true,
                onQuantityChanged: (_) {},
                onGuestAttempt: () {
                  showLoginPromptBottomSheet(context, 0, item);
                },
              );
            }).toList(),
          );
        } else if (state is GuestMenuByRestaurantIdFailure) {
          return const Center(child: Text("Error loading menu"));
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildUserMenuItems() {
    // If we have cached data, show it immediately without any loading
    if (_isDataCached && _cachedMenuItems != null && _cachedMenuItems!.isNotEmpty) {
      print('📦 Displaying cached user menu items - no loading');
      return _buildCachedMenuItems();
    }
    
    return BlocConsumer<GetMenuByRestaurantIdCubit, GetMenuByRestaurantIdState>(
      listener: (context, state) {
        if (state is GetMenuByRestaurantIdLoaded) {
          setState(() {
            if (page == 0) {
              menuItems = state.model.content;
            } else {
              final existingIds = menuItems.map((e) => e.id).toSet();
              menuItems.addAll(
                state.model.content.where((e) => !existingIds.contains(e.id)),
              );
            }
            _isMenuLoaded = true;
            _isLastMenuPage = state.model.last ?? false;
            _isLoadingMore = false;
          });
          
          // Save menu data to cache (only on first page load)
          if (page == 0) {
            _saveMenuToCache(menuItems);
          }
          
          if (!_isCartLoaded) _loadCart();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _maybeAutoloadOfferPages();
          });
        }
      },
      builder: (context, state) {
        if (state is GetMenuByRestaurantIdLoading && menuItems.isEmpty) {
          return const Center(child: CupertinoActivityIndicator());
        } else if (state is GetMenuByRestaurantIdLoaded) {
          final filteredItems = menuItems.where((item) {
            if (_isOfferFlow && (widget.couponCode?.isNotEmpty ?? false)) {
              if (!_matchesOfferBiryani(item)) return false;
            }
            final matchesSearch = (item.name ?? "")
                .toLowerCase()
                .contains(searchText.toLowerCase());
            final foodType = item.attributes
                .firstWhere(
                  (a) => (a.attributeName ?? "").toLowerCase() == 'type',
                  orElse: () =>
                      Attribute(id: 0, attributeName: '', attributeValue: ''),
                )
                .attributeValue
                ?.toLowerCase();
            final matchesFilter = filterType == 'All' ||
                (filterType.toLowerCase() == 'veg' && foodType == 'veg') ||
                (filterType.toLowerCase() == 'nonveg' && foodType == 'nonveg');
            return matchesSearch && matchesFilter;
          }).toList();

          if (filteredItems.isEmpty) {
            return const Center(child: Text("No menu items available"));
          }
          return Column(
            children: [
              ...filteredItems.map((item) {
                final qty = cart[item.name ?? ""] ?? 0;
                return MenuItemWidget(
                  item: item,
                  quantity: qty,
                  restaurantId: widget.restaurantId,
                  restaurantName: widget.restaurantName,
                  isCouponFlow: _isOfferFlow,
                  onQuantityChanged: (newQty) async {
                    if (_isOfferFlow) {
                      final alreadySelected = cart.entries.any((entry) =>
                          entry.value > 0 && entry.key != (item.name ?? ""));
                      if (alreadySelected && newQty == 1 && qty == 0) {
                        _showReplaceItemDialog(item);
                      } else {
                        await update_Cart(item, newQty);
                      }
                    } else {
                      await update_Cart(item, newQty);
                    }
                  },
                );
              }),
              if (_isLoadingMore) const CupertinoActivityIndicator(),
              if (!_isLastMenuPage && !_isLoadingMore)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: OutlinedButton(
                    onPressed: _loadMoreMenu,
                    child: const Text('Load more'),
                  ),
                ),
            ],
          );
        } else if (state is GetMenuByRestaurantIdError) {
          return const Center(child: Text("Error loading menu"));
        }
        if (menuItems.isNotEmpty) {
          return Column(
            children: [
              ...menuItems.map((item) {
                final qty = cart[item.name ?? ""] ?? 0;
                return MenuItemWidget(
                  item: item,
                  quantity: qty,
                  restaurantId: widget.restaurantId,
                  restaurantName: widget.restaurantName,
                  isCouponFlow: _isOfferFlow,
                  onQuantityChanged: (newQty) async {
                    if (_isOfferFlow) {
                      final alreadySelected = cart.entries.any((entry) =>
                          entry.value > 0 && entry.key != (item.name ?? ""));
                      if (alreadySelected && newQty == 1 && qty == 0) {
                        _showReplaceItemDialog(item);
                      } else {
                        await update_Cart(item, newQty);
                      }
                    } else {
                      await update_Cart(item, newQty);
                    }
                  },
                );
              }),
              if (_isLoadingMore) const CupertinoActivityIndicator(),
            ],
          );
        }
        return const Center(child: Text("Loading..."));
      },
    );
  }
}
