import 'package:local_basket/components/custom_topbar.dart';
import 'package:local_basket/core/constants/colors.dart';
import 'package:local_basket/data/model/orders/orderHistory/orderHistory_model.dart';
import 'package:local_basket/presentation/cubit/orders/orderHistory/orderHistory_cubit.dart';
import 'package:local_basket/presentation/cubit/orders/orderHistory/orderHistory_state.dart';
import 'package:local_basket/presentation/cubit/orders/reOrder/reOrder_cubit.dart';
import 'package:local_basket/presentation/cubit/orders/reOrder/reOrder_state.dart';
import 'package:local_basket/presentation/screen/cart/cart_screen.dart';
import 'package:local_basket/presentation/screen/profile/complaints_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';

class MyOrders extends StatefulWidget {
  const MyOrders({super.key});

  @override
  _MyOrdersState createState() => _MyOrdersState();
}

class _MyOrdersState extends State<MyOrders> {
  TextEditingController searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 0;
  final int _pageSize = 10;
  bool _isLoadingMore = false;
  bool _hasMoreItems = true;
  List<Content> _allOrders = [];
  final String _currentSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _fetchInitialOrders();
  }

  void _fetchInitialOrders() {
    _currentPage = 0;
    _hasMoreItems = true;
    _allOrders.clear();
    context
        .read<OrderHistoryCubit>()
        .fetchCart(_currentPage, _pageSize, _currentSearchQuery, context);
  }

  void _fetchMoreOrders() {
    if (!_isLoadingMore && _hasMoreItems) {
      setState(() => _isLoadingMore = true);
      _currentPage++;
      context
          .read<OrderHistoryCubit>()
          .fetchCart(_currentPage, _pageSize, _currentSearchQuery, context);
    }
  }

  void _scrollListener() {
    if (_scrollController.offset >=
            _scrollController.position.maxScrollExtent &&
        !_scrollController.position.outOfRange) {
      _fetchMoreOrders();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "My Orders",
        showBackButton: true,
        onBackPressed: () => Navigator.pop(context),
      ),
      backgroundColor: Colors.white,
      body: BlocListener<ReOrderCubit, ReOrderState>(
        listener: (context, state) async {
          if (state is ReOrderLoading) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => const Center(child: CircularProgressIndicator()),
            );
          } else {
            if (Navigator.canPop(context)) Navigator.pop(context);
            if (state is ReOrderSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reorder successful')),
              );
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartScreen()),
              );
            } else if (state is ReOrderFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          }
        },
        child: Column(
          children: [
            const SizedBox(height: 10),
            Expanded(
              child: BlocConsumer<OrderHistoryCubit, OrderHistoryState>(
                listener: (context, state) {
                  if (state is OrderHistoryLoaded) {
                    final newOrders = state.orders.data?.content ?? [];
                    _hasMoreItems = newOrders.length >= _pageSize;

                    if (_currentPage == 0) {
                      _allOrders = newOrders;
                    } else {
                      _allOrders.addAll(newOrders);
                    }

                    setState(() => _isLoadingMore = false);
                  }
                },
                builder: (context, state) {
                  if (state is OrderHistoryLoading && _currentPage == 0) {
                    return _buildShimmerList();
                  }

                  if (_allOrders.isEmpty) {
                    return const Center(
                      child: Text("No orders found",
                          style: TextStyle(fontSize: 16)),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: _allOrders.length + (_isLoadingMore ? 1 : 0),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    itemBuilder: (context, index) {
                      if (index >= _allOrders.length) {
                        return const Padding(
                          padding: EdgeInsets.all(12),
                          child: CupertinoActivityIndicator(),
                        );
                      }

                      return _buildPremiumOrderCard(_allOrders[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  ///
  /// ADVANCED PREMIUM ORDER CARD
  ///
  Widget _buildPremiumOrderCard(Content order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20), // Bigger Gap Item → Item
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),

        /// Enhanced box-shadow (smooth, premium, deep)
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Header Row
          Row(
            children: [
              Expanded(
                child: Text(
                  order.businessName ?? "",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                "₹${order.totalAmount?.toStringAsFixed(2)}",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColor.PrimaryColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),
          Text(
            "Order ID: ${order.orderNumber}",
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),

          const SizedBox(height: 16),

          _buildCompactItems(order),

          const SizedBox(height: 16),

          _buildMiniTracker(order.orderStatus ?? ""),

          const SizedBox(height: 14),

          Row(
            children: [
              // if ((order.orderStatus ?? '').toUpperCase() == 'DELIVERED')
              //   Expanded(
              //     child: ElevatedButton(
              //       onPressed: () {
              //         final payload = {
              //           "paymentTransactionId": order.paymentTransactionId,
              //           "previousOrderId": order.id,
              //           "updates": order.orderItems
              //               .map((item) => {
              //                     "productId": item.productId,
              //                     "quantity": item.quantity,
              //                   })
              //               .toList(),
              //         };
              //         context.read<ReOrderCubit>().reOrder(payload, context);
              //       },
              //       style: ElevatedButton.styleFrom(
              //         backgroundColor: AppColor.PrimaryColor,
              //         shape: RoundedRectangleBorder(
              //           borderRadius: BorderRadius.circular(12),
              //         ),
              //         padding: const EdgeInsets.symmetric(vertical: 12),
              //       ),
              //       child: const Text(
              //         "Reorder",
              //         style: TextStyle(color: Colors.white, fontSize: 14),
              //       ),
              //     ),
              //   ),

              // if ((order.orderStatus ?? '').toUpperCase() == 'DELIVERED')
              //   const SizedBox(width: 10),

              /// Complaint Button
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ComplaintsScreen(
                          orderId: order.id!,
                          b2bId: order.businessId!,
                          fromOrderHistory: true,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.report, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  ///
  /// Compact item thumbnails
  ///
  Widget _buildCompactItems(Content order) {
    if (order.orderItems.isEmpty) return const SizedBox();

    return SizedBox(
      height: 75,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: order.orderItems.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final item = order.orderItems[i];
          final url = item.media.isNotEmpty ? item.media.first.url : null;

          return Container(
            width: 75,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.07),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: url != null
                  ? Image.network(url, fit: BoxFit.cover)
                  : Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image, size: 30),
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMiniTracker(String status) {
    String normalized = status.toUpperCase();

    /// If rejected → show only RED message
    if (normalized == "REJECTED") {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(Icons.cancel, color: Colors.red.shade400, size: 20),
            const SizedBox(width: 8),
            Text(
              "Order Rejected",
              style: TextStyle(
                color: Colors.red.shade400,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    /// Normal flow for all other statuses
    final stages = [
      "PLACED",
      "PREPARING",
      "OUT_FOR_DELIVERY",
      "DELIVERED",
    ];

    if (normalized == "READY_FOR_PICKUP") {
      normalized = "PREPARING";
    }

    String prettyLabel(String s) {
      return s
          .toLowerCase()
          .replaceAll("_", " ")
          .replaceFirst(s[0].toLowerCase(), s[0]);
    }

    Color softColor(String s) {
      switch (s) {
        case "PLACED":
          return Colors.blue.shade200;
        case "PREPARING":
          return Colors.orange.shade200;
        case "OUT_FOR_DELIVERY":
          return Colors.purple.shade200;
        case "DELIVERED":
          return Colors.green.shade300;
        default:
          return Colors.grey.shade300;
      }
    }

    final currentIndex = stages.indexOf(normalized);

    return Column(
      children: [
        /// Progress Bar
        Stack(
          children: [
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              height: 4,
              width: currentIndex == -1
                  ? 0
                  : (MediaQuery.of(context).size.width *
                      ((currentIndex + 1) / stages.length)),
              decoration: BoxDecoration(
                color: softColor(normalized).withOpacity(0.8),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(stages.length, (i) {
            final active = i <= currentIndex;

            return Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: active ? 18 : 14,
                  height: active ? 18 : 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        active ? softColor(stages[i]) : Colors.grey.shade300,
                    boxShadow: active
                        ? [
                            BoxShadow(
                              color: softColor(stages[i]).withOpacity(0.5),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            )
                          ]
                        : [],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  prettyLabel(stages[i]),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                    color: active ? Colors.black87 : Colors.grey.shade500,
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }

  ///
  /// Shimmer skeleton loader
  ///
  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(
          height: 130,
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
