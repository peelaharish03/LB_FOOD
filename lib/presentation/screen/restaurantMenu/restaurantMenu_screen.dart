import 'dart:async';
import 'dart:io';
import 'package:local_basket/core/constants/restaurant_appbar.dart';
import 'package:local_basket/presentation/cubit/cart/getCart/getCart_cubit.dart';
import 'package:local_basket/presentation/cubit/cart/getCart/getCart_state.dart';
import 'package:local_basket/presentation/cubit/cart/productsAddToCart/productsAddtoCart_cubit.dart';
import 'package:local_basket/presentation/screen/authentication/login_screen.dart';
import 'package:local_basket/presentation/screen/widgets/restaurantMenu/searchBar.dart';
import 'package:local_basket/presentation/screen/widgets/restaurantMenu/bottomSheet.dart';
import 'package:local_basket/presentation/screen/widgets/restaurantMenu/menu.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_basket/core/constants/colors.dart';
import 'package:local_basket/presentation/screen/cart/cart_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  int totalItems = 0, page = 0, size = 300;
  PersistentBottomSheetController? _bottomSheetController;
  bool get _isCouponFlow => widget.couponCode != null;
  bool isBottomSheetVisible = false;
  String searchText = '', filterType = 'All';
  List<Content> selectedItems = [], menuItems = [];
  Timer? _debounce;
  bool _isMenuLoaded = false;
  bool _isCartLoaded = false;
  Content? _couponSelectedItem;

  @override
  void initState() {
    super.initState();

    print("RestaurantMenuScreen - isGuest: ${widget.isGuest}");

    WidgetsBinding.instance.addPostFrameCallback((_) {
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
            onPressed: () {
              Navigator.of(ctx).pop();

              if (_couponSelectedItem != null) {
                cart.remove(_couponSelectedItem!.name);
                final oldIndex = menuItems
                    .indexWhere((m) => m.id == _couponSelectedItem!.id);
                if (oldIndex != -1) {
                  menuItems = List.from(menuItems);
                }
              }

              _couponSelectedItem = newItem;
              update_Cart(newItem, 1);
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
    await context.read<GetMenuByRestaurantIdCubit>().fetchMenu({
      'restaurantId': widget.restaurantId,
      'search': searchText,
      'page': page,
      'size': size,
    });
  }

  void update_Cart(Content item, int qty) {
    if (_isCouponFlow) {
      if (_couponSelectedItem != null && _couponSelectedItem!.id != item.id) {}

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
      bool selfOrder = true;
      if (cartState is GetCartLoaded) {
        notes = cartState.cart.notes ?? "";
        selfOrder = cartState.cart.selfOrder ?? true;
      }

      final Map<String, dynamic> payload = {
        "notes": notes,
        "selfOrder": selfOrder,
        "items": items,
      };
      context.read<ProductsAddToCartCubit>().addToCart(payload);
      context.read<GetCartCubit>().fetchCart(context);

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
    bool selfOrder = true;

    if (cartState is GetCartLoaded) {
      notes = cartState.cart.notes ?? "";
      selfOrder = cartState.cart.selfOrder ?? true;
    }

    final Map<String, dynamic> payload = {
      "notes": notes,
      "selfOrder": selfOrder,
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
    _bottomSheetController =
        _scaffoldKey.currentState!.showBottomSheet((context) {
      return RestaurantCartBottomSheet(
        totalItems: totalItems,
        onViewCartPressed: () async {
          _bottomSheetController?.close();
          final result = await Navigator.push(
            context,
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

              _onBottomSheetVisibilityChanged(false);
              await Future.delayed(const Duration(milliseconds: 100));

              if (mounted && cart.isNotEmpty) {
                showPersistentCart();
              }

              if (!widget.isGuest) _loadMenu();
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

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() {
        searchText = value;
      });
      if (!widget.isGuest) {
        _loadMenu();
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
        body: SingleChildScrollView(
          padding: const EdgeInsets.only(
              bottom: 100), // space for floating buttons/cart
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // AppBar
              SwiggyStyleAppBar(
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
              ),

              SizedBox(
                height:
                    Platform.isIOS ? 80 : 100, 
              ),

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
                                          AppColor.PrimaryColor.withAlpha(50),
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
      ),
    );
  }

  Widget _buildGuestMenuItems() {
    return BlocConsumer<GuestMenuByRestaurantIdCubit,
        GuestMenuByRestaurantIdState>(
      listener: (context, state) {
        if (state is GuestMenuByRestaurantIdSuccess) _isMenuLoaded = true;
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

          if (filteredItems.isEmpty)
            return const Center(child: Text("No menu items available"));

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
    return BlocConsumer<GetMenuByRestaurantIdCubit, GetMenuByRestaurantIdState>(
      listener: (context, state) {
        if (state is GetMenuByRestaurantIdLoaded) {
          setState(() {
            menuItems = state.model.content;
            _isMenuLoaded = true;
          });
          if (!_isCartLoaded) _loadCart();
        }
      },
      builder: (context, state) {
        if (state is GetMenuByRestaurantIdLoading) {
          return const Center(child: CupertinoActivityIndicator());
        } else if (state is GetMenuByRestaurantIdLoaded) {
          final filteredItems = menuItems.where((item) {
            if (_isCouponFlow && item.categoryId != 2) return false;
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

          if (filteredItems.isEmpty)
            return const Center(child: Text("No menu items available"));

          return Column(
            children: filteredItems.map((item) {
              final qty = cart[item.name ?? ""] ?? 0;
              return MenuItemWidget(
                item: item,
                quantity: qty,
                restaurantId: widget.restaurantId,
                restaurantName: widget.restaurantName,
                isCouponFlow: _isCouponFlow,
                onQuantityChanged: (newQty) {
                  if (_isCouponFlow) {
                    final alreadySelected = cart.entries.any((entry) =>
                        entry.value > 0 && entry.key != (item.name ?? ""));
                    if (alreadySelected && newQty == 1 && qty == 0) {
                      _showReplaceItemDialog(item);
                    } else {
                      update_Cart(item, 1);
                    }
                  } else {
                    update_Cart(item, newQty);
                  }
                },
              );
            }).toList(),
          );
        } else if (state is GetMenuByRestaurantIdError) {
          return const Center(child: Text("Error loading menu"));
        }
        return const Center(child: Text("Loading..."));
      },
    );
  }
}
