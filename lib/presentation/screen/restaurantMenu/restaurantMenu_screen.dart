import 'dart:async';
import 'dart:convert';
import 'package:local_basket/core/constants/restaurant_appbar.dart';
import 'package:local_basket/presentation/cubit/cart/getCart/getCart_cubit.dart';
import 'package:local_basket/presentation/cubit/cart/getCart/getCart_state.dart';
import 'package:local_basket/presentation/cubit/cart/productsAddToCart/productsAddtoCart_cubit.dart';
import 'package:local_basket/presentation/cubit/cart/updateCartItems/updateCartItems_cubit.dart';
import 'package:local_basket/presentation/screen/widgets/restaurantMenu/searchBar.dart';
import 'package:local_basket/presentation/screen/widgets/restaurantMenu/bottomSheet.dart';
import 'package:local_basket/presentation/screen/widgets/restaurantMenu/menu.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:local_basket/core/constants/colors.dart';
import 'package:local_basket/presentation/screen/cart/cart_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_basket/data/model/restaurants/menu_content_model.dart';
import 'package:local_basket/presentation/cubit/restaurants/getMenuByRestaurantId/getMenuByRestaurantId_cubit.dart';
import 'package:local_basket/presentation/cubit/restaurants/getMenuByRestaurantId/getMenuByRestaurantId_state.dart';

class RestaurantMenuScreen extends StatefulWidget {
  final String restaurantName, restaurantId;
  final String? b2bUnitId;
  final String? couponCode;
  const RestaurantMenuScreen({
    super.key,
    required this.restaurantName,
    required this.restaurantId,
    this.b2bUnitId,
    this.couponCode,
  });

  @override
  _RestaurantMenuScreenState createState() => _RestaurantMenuScreenState();
}

class _RestaurantMenuScreenState extends State<RestaurantMenuScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  Map<String, int> cart = {};
  int totalItems = 0, page = 0, size = 100;
  PersistentBottomSheetController? _bottomSheetController;
  bool _isOfferFlow = false;
  bool isBottomSheetVisible = false;
  bool _showBackButton = true;
  String searchText = '', filterType = 'All';
  List<Content> selectedItems = [], menuItems = [];
  Timer? _debounce;
  bool _isMenuLoaded = false;
  bool _isCartLoaded = false;
  bool _isNavigatingBack = false;
  bool _allowPop = false;
  bool _isLoadingMore = false;
  bool _isLastMenuPage = false;
  final ScrollController _scrollController = ScrollController();
  int _offerAutoLoadAttempts = 0;
  String? cartId;

  // Cache variables
  bool _isDataCached = false;
  List<Map<String, dynamic>>? _cachedMenuItems;
  static const String _menuCacheTimestampKey = 'menu_cache_timestamp';
  static const String _menuCacheRestaurantIdKey = 'menu_cache_restaurant_id';
  static const String _menuCacheDataKey = 'menu_cache_data';
  static const Duration _menuCacheExpiry = Duration(
    minutes: 5,
  ); // Cache for 5 minutes

  // Background refresh
  static const Duration _menuRefreshInterval = Duration(seconds: 30);
  Timer? _menuRefreshTimer;
  bool _isRefreshingMenu = false;

  @override
  void initState() {
    super.initState();
    print(
      'RestaurantMenuScreen initialized with restaurantId: ${widget.restaurantId}, couponCode: ${widget.restaurantName}',
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      () async {
        final prefs = await SharedPreferences.getInstance();
        final storedCartId = prefs.get('cart_id')?.toString();
        if (_hasValidCartId(storedCartId)) {
          cartId = storedCartId;
        }
        final hasCoupon = (widget.couponCode?.isNotEmpty ?? false);
        final stickyOffer = prefs.getBool('is_offer_flow') ?? false;

        if (!hasCoupon && stickyOffer) {
          await prefs.remove('is_offer_flow');
        }

        if (mounted) setState(() => _isOfferFlow = hasCoupon);
      }();

      // Check for cached menu data first
      _checkCachedMenuData();

      // Start background refresh so backend changes are picked up automatically
      _menuRefreshTimer = Timer.periodic(
        _menuRefreshInterval,
        (_) => _refreshMenuInBackground(),
      );

      // Kick off an immediate first refresh so stale cached data is replaced fast
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) _refreshMenuInBackground();
      });

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
    });
  }

  void _showReplaceItemDialog(Content newItem) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: const Text("Replace item?"),
            content: const Text(
              "You can only select one item with this coupon. Do you want to replace your current item with the new one?",
            ),
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

                  await update_Cart(newItem, 1);
                },
                child: const Text("Replace"),
              ),
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

  Future<void> _persistCartId(String? id) async {
    if (!_hasValidCartId(id)) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cart_id', id!);
  }

  Future<String?> _ensureCartId() async {
    final currentCartId = cartId;
    if (_hasValidCartId(currentCartId)) {
      return currentCartId;
    }

    final prefs = await SharedPreferences.getInstance();
    final storedCartId = prefs.get('cart_id')?.toString();
    if (_hasValidCartId(storedCartId)) {
      if (mounted) {
        setState(() => cartId = storedCartId);
      } else {
        cartId = storedCartId;
      }
      return storedCartId;
    }

    final cartState = context.read<GetCartCubit>().state;
    if (cartState is GetCartLoaded) {
      final loadedCartId = cartState.cart.id;
      if (_hasValidCartId(loadedCartId)) {
        await _persistCartId(loadedCartId);
        if (mounted) {
          setState(() => cartId = loadedCartId);
        } else {
          cartId = loadedCartId;
        }
        return loadedCartId;
      }
    }

    await context.read<GetCartCubit>().fetchCart(context);
    final refreshedCartState = context.read<GetCartCubit>().state;
    if (refreshedCartState is GetCartLoaded) {
      final refreshedCartId = refreshedCartState.cart.id;
      if (_hasValidCartId(refreshedCartId)) {
        await _persistCartId(refreshedCartId);
        if (mounted) {
          setState(() => cartId = refreshedCartId);
        } else {
          cartId = refreshedCartId;
        }
        return refreshedCartId;
      }
    }

    return null;
  }

  bool _hasValidCartId(String? id) {
    final normalized = id?.trim();
    return normalized != null &&
        normalized.isNotEmpty &&
        normalized != '0' &&
        normalized.toLowerCase() != 'null';
  }

  String? _productIdForPayload(Content item) {
    final productId = item.id?.toString();
    if (productId == null || productId.isEmpty || productId == '0') {
      return null;
    }
    return productId;
  }

  Map<String, dynamic>? _singleItemCartPayload(Content item, int quantity) {
    final productId = _productIdForPayload(item);
    if (productId == null) return null;
    return {"productId": productId, "quantity": quantity};
  }

  String? _storeIdForItem(Content item) {
    final itemStoreId = item.businessId?.toString();
    if (itemStoreId != null && itemStoreId.isNotEmpty && itemStoreId != '0') {
      return itemStoreId;
    }
    return widget.restaurantId;
  }

  String? _cartStoreIdFromState() {
    final cartState = context.read<GetCartCubit>().state;
    if (cartState is! GetCartLoaded) return null;
    final storeId = cartState.cart.storeId;
    return storeId == null || storeId.isEmpty ? null : storeId;
  }

  bool _cartHasBackendItems() {
    final cartState = context.read<GetCartCubit>().state;
    if (cartState is! GetCartLoaded) return false;
    return cartState.cart.cartItems.any((item) => (item.quantity ?? 0) > 0);
  }

  String? _cartItemIdFromState(dynamic productId) {
    final cartState = context.read<GetCartCubit>().state;
    if (cartState is! GetCartLoaded) return null;

    for (final cartItem in cartState.cart.cartItems) {
      if (_sameId(cartItem.productId, productId)) {
        return cartItem.id;
      }
    }
    return null;
  }

  Future<String?> _cartItemIdForProductId(dynamic productId) async {
    var cartItemId = _cartItemIdFromState(productId);
    if (_hasValidCartId(cartItemId)) return cartItemId;

    await context.read<GetCartCubit>().fetchCart(context);
    cartItemId = _cartItemIdFromState(productId);
    return _hasValidCartId(cartItemId) ? cartItemId : null;
  }

  Future<void> _updateExistingCartItemQuantity(
    String activeCartId,
    Content item,
    int quantity,
  ) async {
    final cartItemId = await _cartItemIdForProductId(item.id);
    if (!_hasValidCartId(cartItemId)) {
      debugPrint('Cart item id unavailable. Skipping cart item update.');
      return;
    }

    await context.read<UpdateCartItemsCubit>().updateCartItem(
      {"quantity": quantity},
      activeCartId,
      cartItemId!,
      context,
    );
  }

  Future<void> _removeAllExistingCartItems(String activeCartId) async {
    final cartState = context.read<GetCartCubit>().state;
    if (cartState is! GetCartLoaded) return;

    for (final cartItem in cartState.cart.cartItems) {
      final cartItemId = cartItem.id;
      final quantity = cartItem.quantity ?? 0;
      if (quantity <= 0 || !_hasValidCartId(cartItemId)) continue;

      await context.read<UpdateCartItemsCubit>().updateCartItem(
        {"quantity": 0},
        activeCartId,
        cartItemId!,
        context,
      );
    }
  }

  Future<bool> _confirmStoreSwitchIfNeeded(
    String activeCartId,
    Content item,
    int previousQty,
  ) async {
    if (previousQty > 0) return true;

    if (context.read<GetCartCubit>().state is! GetCartLoaded) {
      await context.read<GetCartCubit>().fetchCart(context);
      if (!mounted) return false;
    }

    final cartHasItems = totalItems > 0 || _cartHasBackendItems();
    if (!cartHasItems) return true;

    final cartStoreId = _cartStoreIdFromState();
    final itemStoreId = _storeIdForItem(item);
    if (cartStoreId == null ||
        itemStoreId == null ||
        cartStoreId == itemStoreId) {
      return true;
    }

    final shouldReplace = await showReplaceCartDialog(
      context: context,
      currentRestaurant: 'another restaurant',
      newRestaurant: widget.restaurantName,
    );
    if (shouldReplace != true) return false;

    await _removeAllExistingCartItems(activeCartId);
    await context.read<GetCartCubit>().fetchCart(context);
    if (!mounted) return false;

    setState(() {
      cart.clear();
      selectedItems.clear();
      totalItems = 0;
      _isCartLoaded = false;
    });

    if (isBottomSheetVisible) {
      _bottomSheetController?.close();
      _onBottomSheetVisibilityChanged(false);
    }

    return true;
  }

  void _processCartData(GetCartLoaded state) {
    final loadedCartId = state.cart.id;
    if (_hasValidCartId(loadedCartId)) {
      cartId = loadedCartId;
      _persistCartId(loadedCartId);
    }

    final cartStoreId = state.cart.storeId;
    if (cartStoreId != null &&
        cartStoreId.isNotEmpty &&
        cartStoreId != widget.restaurantId) {
      return;
    }
    if (!_isMenuLoaded) return;

    int itemCounter = 0;
    Map<String, int> updatedCart = {};
    List<Content> updatedSelectedItems = [];

    for (var cartItem in state.cart.cartItems) {
      final menuItem = menuItems.firstWhere(
        (item) => _sameId(item.id, cartItem.productId),
        orElse:
            () => Content(
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

      if (_hasRealId(menuItem)) {
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

  bool _sameId(dynamic left, dynamic right) {
    return left != null && right != null && left.toString() == right.toString();
  }

  bool _hasRealId(Content item) {
    final id = item.id?.toString() ?? '';
    return id.isNotEmpty && id != '0';
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  double _effectivePrice(Content item) {
    final onlinePriceAttr = item.attributes.firstWhere(
      (attr) => attr.attributeName?.toLowerCase() == 'onlineprice',
      orElse:
          () => Attribute(id: null, attributeName: null, attributeValue: null),
    );

    return _toDouble(onlinePriceAttr.attributeValue) ??
        _toDouble(item.price) ??
        0;
  }

  Future<void> _loadMenu() async {
    print('Loading menu with search: "$searchText", filterType: "$filterType"');
    page = 0;
    _isLastMenuPage = false;
    _isLoadingMore = false;
    _isMenuLoaded = false;
    menuItems = [];
    _offerAutoLoadAttempts = 0;

    // Check if we have cached data first
    if (await _hasValidMenuCache()) {
      print('📦 Using cached menu data - no API call');
      return;
    }

    await context.read<GetMenuByRestaurantIdCubit>().fetchMenu({
      'restaurantId': widget.restaurantId,
      'b2bUnitId': widget.b2bUnitId,
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
    if (_isLastMenuPage) return;
    if (_isLoadingMore) return;
    if (!_isMenuLoaded) return;
    setState(() => _isLoadingMore = true);
    page = page + 1;
    await context.read<GetMenuByRestaurantIdCubit>().fetchMenu({
      'restaurantId': widget.restaurantId,
      'b2bUnitId': widget.b2bUnitId,
      'search': searchText,
      'page': page,
      'size': size,
    });
  }

  Future<void> _refreshMenuInBackground() async {
    if (!mounted) return;
    if (_isRefreshingMenu) return;
    if (!_isMenuLoaded) return;

    _isRefreshingMenu = true;
    try {
      debugPrint('🔄 Background refresh of restaurant menu');
      await context.read<GetMenuByRestaurantIdCubit>().refreshMenu({
        'restaurantId': widget.restaurantId,
        'b2bUnitId': widget.b2bUnitId,
        'search': searchText,
        'page': 0,
        'size': size,
      });
    } catch (e) {
      debugPrint('❌ Background menu refresh failed: $e');
    } finally {
      _isRefreshingMenu = false;
    }
  }

  // Cache management methods
  Future<void> _checkCachedMenuData() async {
    if (await _hasValidMenuCache()) {
      print('📦 Loading menu from cache');
      await _loadMenuFromCache();

      // Load cart after menu is loaded from cache
      Future.delayed(const Duration(milliseconds: 300), () {
        _loadCart();
      });
    } else {
      context.read<GetMenuByRestaurantIdCubit>().fetchMenu({
        'restaurantId': widget.restaurantId,
        'b2bUnitId': widget.b2bUnitId,
        'search': searchText,
        'page': page,
        'size': size,
      });
      Future.delayed(const Duration(milliseconds: 300), () {
        _loadCart();
      });
    }
  }

  Future<bool> _hasValidMenuCache() async {
    final prefs = await SharedPreferences.getInstance();

    final cachedTimestamp = prefs.getInt(_menuCacheTimestampKey);
    final cachedRestaurantId = prefs.getString(_menuCacheRestaurantIdKey);

    if (cachedTimestamp == null || cachedRestaurantId == null) {
      print('📦 No menu cache metadata found');
      return false;
    }

    // Check if restaurant ID matches
    if (cachedRestaurantId != widget.restaurantId) {
      print('📦 Restaurant ID changed, invalidating menu cache');
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
    menuItems =
        _cachedMenuItems!
            .map(
              (item) => Content(
                id: item['id'] ?? 0,
                name: item['name'] ?? '',
                shortCode: item['shortCode'] ?? '',
                ignoreTax: item['ignoreTax'] ?? false,
                discount: item['discount'] ?? true,
                description: item['description'] ?? '',
                price: item['price'] ?? 0,
                available: item['available'] ?? false,
                shopifyProductId: item['shopifyProductId'] ?? '',
                shopifyVariantId: item['shopifyVariantId'] ?? '',
                businessId: item['businessId'] ?? 0,
                categoryId: item['categoryId'] ?? 0,
                categoryName: item['categoryName'] ?? '',
                media:
                    (item['media'] as List<dynamic>?)
                        ?.map(
                          (m) => Media(
                            mediaType: m['mediaType'] ?? '',
                            url: m['url'] ?? '',
                          ),
                        )
                        .toList() ??
                    [],
                attributes:
                    (item['attributes'] as List<dynamic>?)
                        ?.map(
                          (a) => Attribute(
                            id: a['id'] ?? 0,
                            attributeName: a['attributeName'] ?? '',
                            attributeValue: a['attributeValue'] ?? '',
                          ),
                        )
                        .toList() ??
                    [],
              ),
            )
            .toList();

    setState(() {
      _isMenuLoaded = true;
      _isDataCached = true;
    });
  }

  Future<void> _saveMenuToCache(List<Content> menuData) async {
    final prefs = await SharedPreferences.getInstance();

    try {
      // Convert menu items to JSON for storage
      final menuJson =
          menuData
              .map(
                (item) => {
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
                  'categoryName': item.categoryName,
                  'media':
                      item.media
                          ?.map((m) => {'mediaType': m.mediaType, 'url': m.url})
                          .toList() ??
                      [],
                  'attributes':
                      item.attributes
                          .map(
                            (a) => {
                              'id': a.id,
                              'attributeName': a.attributeName,
                              'attributeValue': a.attributeValue,
                            },
                          )
                          .toList(),
                },
              )
              .toList();

      await prefs.setString(_menuCacheDataKey, jsonEncode(menuJson));
      await prefs.setInt(
        _menuCacheTimestampKey,
        DateTime.now().millisecondsSinceEpoch,
      );
      await prefs.setString(_menuCacheRestaurantIdKey, widget.restaurantId);

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
    _cachedMenuItems = null;
    print('📦 Cleared menu cache');
  }

  Future<void> update_Cart(Content item, int qty) async {
    if (item.available != true) {
      debugPrint('Item is not active. Skipping cart update.');
      return;
    }

    final activeCartId = await _ensureCartId();
    if (!_hasValidCartId(activeCartId)) {
      debugPrint('Cart id unavailable. Skipping cart update.');
      return;
    }

    final itemName = item.name ?? "";
    final previousQty = cart[itemName] ?? 0;
    if (qty == previousQty || (qty < previousQty && previousQty <= 0)) {
      return;
    }

    if (qty > 0) {
      final canUpdateCart = await _confirmStoreSwitchIfNeeded(
        activeCartId!,
        item,
        previousQty,
      );
      if (!canUpdateCart) {
        if (mounted) setState(() {});
        return;
      }
    }

    if (_isOfferFlow && qty > 0) {
      for (final selectedItem in List<Content>.from(selectedItems)) {
        if (_sameId(selectedItem.id, item.id)) continue;
        final selectedQty = cart[selectedItem.name] ?? 0;
        if (selectedQty <= 0) continue;
        await _updateExistingCartItemQuantity(activeCartId!, selectedItem, 0);
      }
    }

    var updatedCart = Map<String, int>.from(cart);
    var updatedSelectedItems = List<Content>.from(selectedItems);

    if (qty == 0) {
      updatedCart.remove(itemName);
      updatedSelectedItems.removeWhere((i) => i.name == item.name);
    } else {
      if (_isOfferFlow) {
        updatedCart.clear();
        updatedSelectedItems.clear();
      }
      updatedCart[itemName] = qty;
      if (!updatedSelectedItems.any((i) => _sameId(i.id, item.id))) {
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

    if (previousQty <= 0 && qty > 0) {
      final payload = _singleItemCartPayload(item, 1);
      if (payload == null) return;
      debugPrint('ProductsAddToCart Payload: $payload');
      await context.read<ProductsAddToCartCubit>().addToCart(
        activeCartId,
        payload,
        context: context,
      );
    } else {
      debugPrint('UpdateCartItems Payload: {"quantity": $qty}');
      await _updateExistingCartItemQuantity(activeCartId!, item, qty);
    }
    await context.read<GetCartCubit>().fetchCart(context);

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
    _bottomSheetController = _scaffoldKey.currentState!.showBottomSheet((
      bottomSheetContext,
    ) {
      return RestaurantCartBottomSheet(
        totalItems: totalItems,
        onViewCartPressed: () async {
          _bottomSheetController?.close();
          final result = await Navigator.push(
            rootContext,
            MaterialPageRoute(
              builder:
                  (_) => CartScreen(
                    cartItems:
                        selectedItems.map((item) {
                          return {
                            'cartItemId': _cartItemIdFromState(item.id),
                            'productId': item.id,
                            'quantity': cart[item.name] ?? 0,
                            'price': _effectivePrice(item),
                            'name': item.name,
                            'description': item.description,
                            'categoryName':
                                item.attributes
                                    .firstWhere(
                                      (a) =>
                                          a.attributeName?.toLowerCase() ==
                                          'type',
                                      orElse:
                                          () => Attribute(
                                            id: 0,
                                            attributeName: '',
                                            attributeValue: '',
                                          ),
                                    )
                                    .attributeValue,
                            'media': item.media,
                          };
                        }).toList(),
                    onBottomSheetVisibilityChanged:
                        _onBottomSheetVisibilityChanged,
                  ),
            ),
          );

          if (!mounted) return;

          if (result != null && result is Map<String, dynamic>) {
            final updatedCart = result['updatedCart'];
            final updatedCartLength = result['cartItemsLength'] ?? 0;

            if (updatedCart is Map) {
              setState(() {
                cart.clear();
                selectedItems.clear();

                for (var entry in updatedCart.entries) {
                  final productId = entry.key;
                  final quantity =
                      entry.value is int
                          ? entry.value as int
                          : int.tryParse(entry.value.toString()) ?? 0;

                  final item = menuItems.firstWhere(
                    (item) => _sameId(item.id, productId),
                    orElse:
                        () => Content(
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

                  if (_hasRealId(item)) {
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

              // Refresh cart from backend to ensure full consistency without
              // clearing the already loaded menu list.
              await rootContext.read<GetCartCubit>().fetchCart(rootContext);
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

  Map<dynamic, int> _buildReturnCart() {
    final updatedCart = <dynamic, int>{};
    for (final item in selectedItems) {
      final productId = item.id;
      final qty = cart[item.name] ?? 0;
      if (productId != null && qty > 0) {
        updatedCart[productId] = qty;
      }
    }
    return updatedCart;
  }

  Future<void> _handleBackNavigation() async {
    if (_isNavigatingBack) return;
    _isNavigatingBack = true;

    try {
      if (isBottomSheetVisible && _bottomSheetController != null) {
        _bottomSheetController?.close();
        await Future.delayed(const Duration(milliseconds: 150));
      }

      if (!mounted) return;
      setState(() => _allowPop = true);
      await Future<void>.delayed(Duration.zero);
      if (!mounted) return;

      Navigator.of(
        context,
      ).pop({'updatedCart': _buildReturnCart(), 'cartItemsLength': totalItems});
    } finally {
      _isNavigatingBack = false;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _menuRefreshTimer?.cancel();
    _menuRefreshTimer = null;
    _bottomSheetController?.close();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _allowPop,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        await _handleBackNavigation();
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.grey[100],
        body: Stack(
          children: [
            SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.only(top: 300, bottom: 100),
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
                            onTap: () {
                              setState(() {
                                filterType = filter;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
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
                                          color: AppColor.PrimaryColor
                                              .withAlpha(50),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
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
                    child: _buildUserMenuItems(),
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
                onBackPressed: _handleBackNavigation,
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
    final filteredItems =
        menuItems.where((item) {
          if (_isOfferFlow && (widget.couponCode?.isNotEmpty ?? false)) {
            if (!_matchesOfferBiryani(item)) return false;
          }
          final matchesSearch = (item.name ?? "").toLowerCase().contains(
            searchText.toLowerCase(),
          );
          final matchesFilter =
              filterType == 'All' ||
              (filterType == 'Veg' && item.foodType == 'veg') ||
              (filterType == 'NonVeg' && item.foodType == 'nonveg');
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
                final alreadySelected = cart.entries.any(
                  (entry) => entry.value > 0 && entry.key != item.name,
                );
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

  Widget _buildUserMenuItems() {
    // If we have cached data, show it immediately without any loading
    if (_isDataCached &&
        _cachedMenuItems != null &&
        _cachedMenuItems!.isNotEmpty) {
      print('📦 Displaying cached user menu items - no loading');
      return _buildCachedMenuItems();
    }

    return BlocConsumer<GetMenuByRestaurantIdCubit, GetMenuByRestaurantIdState>(
      listener: (context, state) {
        if (state is GetMenuByRestaurantIdLoaded) {
          final responsePage = state.model.number ?? page;
          final isFirstPage = responsePage == 0;
          setState(() {
            if (isFirstPage) {
              menuItems = state.model.content;
            } else {
              final existingIds = menuItems.map((e) => e.id.toString()).toSet();
              menuItems.addAll(
                state.model.content.where(
                  (e) => !existingIds.contains(e.id.toString()),
                ),
              );
            }
            _isMenuLoaded = true;
            _isLastMenuPage = state.model.last ?? false;
            _isLoadingMore = false;
            page = responsePage;
          });

          // Save menu data to cache (only on first page load)
          if (isFirstPage) {
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
          final filteredItems =
              menuItems.where((item) {
                if (_isOfferFlow && (widget.couponCode?.isNotEmpty ?? false)) {
                  if (!_matchesOfferBiryani(item)) return false;
                }
                final matchesSearch = (item.name ?? "").toLowerCase().contains(
                  searchText.toLowerCase(),
                );
                final matchesFilter =
                    filterType == 'All' ||
                    (filterType.toLowerCase() == 'veg' &&
                        item.foodType == 'veg') ||
                    (filterType.toLowerCase() == 'nonveg' &&
                        item.foodType == 'nonveg');
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
                      final alreadySelected = cart.entries.any(
                        (entry) =>
                            entry.value > 0 && entry.key != (item.name ?? ""),
                      );
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
                      final alreadySelected = cart.entries.any(
                        (entry) =>
                            entry.value > 0 && entry.key != (item.name ?? ""),
                      );
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
