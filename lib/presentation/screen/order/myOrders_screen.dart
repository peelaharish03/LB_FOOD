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
  int _nextPage = 0;
  final int _pageSize = 20;
  bool _isInitialLoading = false;
  bool _isLoadingMore = false;
  bool _hasMoreItems = true;
  final List<Content> _allOrders = [];
  final Set<int> _pagesInFlight = <int>{};
  final Set<int> _loadedPages = <int>{};
  final String _currentSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchInitialOrders();
  }

  @override
  void dispose() {
    searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _fetchInitialOrders() {
    _nextPage = 0;
    _isInitialLoading = true;
    _isLoadingMore = false;
    _hasMoreItems = true;
    _allOrders.clear();
    _pagesInFlight.clear();
    _loadedPages.clear();
    _fetchOrdersPage(0);
  }

  void _fetchOrdersPage(int page) {
    if (_pagesInFlight.contains(page) || _loadedPages.contains(page)) return;
    _pagesInFlight.add(page);
    context.read<OrderHistoryCubit>().fetchCart(
      page,
      _pageSize,
      _currentSearchQuery,
      context,
    );
  }

  void _fetchMoreOrders() {
    if (_isInitialLoading || _isLoadingMore || !_hasMoreItems) return;

    final page = _nextPage;
    if (_pagesInFlight.contains(page) || _loadedPages.contains(page)) return;

    setState(() => _isLoadingMore = true);
    _fetchOrdersPage(page);
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    final metrics = notification.metrics;
    if (metrics.axis != Axis.vertical || metrics.maxScrollExtent <= 0) {
      return false;
    }

    final isScrollingDown =
        notification is ScrollUpdateNotification &&
        (notification.scrollDelta ?? 0) > 0;
    final isOverscrollingBottom =
        notification is OverscrollNotification && notification.overscroll > 0;

    if ((isScrollingDown || isOverscrollingBottom) &&
        metrics.extentAfter < 300) {
      _fetchMoreOrders();
    }

    return false;
  }

  void _handleOrdersLoaded(OrderHistoryLoaded state) {
    final page = state.page;
    final wasRequested = _pagesInFlight.remove(page);

    if (!wasRequested && _loadedPages.contains(page)) return;
    if (!wasRequested && page > 0) return;

    final data = state.orders.data;
    final newOrders = data?.content ?? [];

    setState(() {
      if (page == 0) {
        _allOrders
          ..clear()
          ..addAll(newOrders);
        _loadedPages
          ..clear()
          ..add(page);
        _nextPage = 1;
      } else if (!_loadedPages.contains(page)) {
        _appendUniqueOrders(newOrders);
        _loadedPages.add(page);
        if (_nextPage <= page) _nextPage = page + 1;
      }

      _hasMoreItems = !(data?.last ?? newOrders.length < _pageSize);
      if (newOrders.isEmpty) _hasMoreItems = false;
      _isInitialLoading = false;
      _isLoadingMore = false;
    });
  }

  void _handleOrdersError(OrderHistoryError state) {
    final wasRequested = _pagesInFlight.remove(state.page);
    if (!wasRequested) return;

    setState(() {
      if (state.page == 0) _isInitialLoading = false;
      _isLoadingMore = false;
    });
  }

  void _appendUniqueOrders(List<Content> orders) {
    final existingIds =
        _allOrders.map((order) => order.id).whereType<String>().toSet();

    for (final order in orders) {
      final id = order.id;
      if (id == null || existingIds.add(id)) {
        _allOrders.add(order);
      }
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
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
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
                    _handleOrdersLoaded(state);
                  } else if (state is OrderHistoryError) {
                    _handleOrdersError(state);
                  }
                },
                builder: (context, state) {
                  if (_isInitialLoading && _allOrders.isEmpty) {
                    return _buildShimmerList();
                  }

                  if (state is OrderHistoryError && _allOrders.isEmpty) {
                    return Center(
                      child: Text(
                        state.message.isEmpty
                            ? "Failed to load orders"
                            : state.message,
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  if (_allOrders.isEmpty) {
                    return const Center(
                      child: Text(
                        "No orders found",
                        style: TextStyle(fontSize: 16),
                      ),
                    );
                  }

                  return NotificationListener<ScrollNotification>(
                    onNotification: _handleScrollNotification,
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      itemCount:
                          _allOrders.length +
                          (_isLoadingMore ? 1 : 0) +
                          (!_hasMoreItems && _allOrders.isNotEmpty ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index < _allOrders.length) {
                          return _buildPremiumOrderCard(_allOrders[index]);
                        }

                        if (_isLoadingMore && index == _allOrders.length) {
                          return const Padding(
                            padding: EdgeInsets.all(12),
                            child: CupertinoActivityIndicator(),
                          );
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Center(
                            child: Text(
                              'You’ve reached the end of your orders',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _effectiveStatus(Content order) {
    return order.orderStatus ??
        order.paymentStatus ??
        (order.orderItems.isEmpty ? null : order.orderItems.first.status) ??
        'PENDING';
  }

  String _statusLabel(Content order) {
    final status = _effectiveStatus(order).toUpperCase();
    switch (status) {
      case 'PICKED_UP':
      case 'IN_DELIVERY':
        return 'Out for delivery';
      case 'CONFIRMED':
        return 'Preparing';
      case 'PREPARING':
        return 'Preparing';
      case 'DELIVERED':
        return 'Delivered';
      default:
        return status.replaceAll('_', ' ');
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Completed':
      case 'PAYMENT COMPLETED':
      case 'DELIVERED':
      case 'Delivered':
      case 'COMPLETED':
        return Colors.green.shade700;
      case 'Confirmed':
      case 'CONFIRMED':
        return Colors.blue.shade700;
      case 'PREPARING':
      case 'Preparing':
        return Colors.orange.shade700;
      case 'Out for delivery':
      case 'PICKED UP':
      case 'OUT FOR DELIVERY':
      case 'PICKED_UP':
        return Colors.purple.shade700;
      case 'READY':
        return Colors.purple.shade700;
      case 'Cancelled':
      case 'REJECTED':
      case 'CANCELLED':
      case 'CANCELED':
      case 'FAILED':
        return Colors.red.shade700;
      default:
        return Colors.orange.shade700;
    }
  }

  Widget _buildOrderStatusChip(Content order) {
    final label = _statusLabel(order);
    final color = _statusColor(label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }

  String _orderTitle(Content order) {
    final firstItemName =
        order.orderItems.isEmpty ? null : order.orderItems.first.productName;
    if (firstItemName != null && firstItemName.trim().isNotEmpty) {
      final remaining = order.orderItems.length - 1;
      if (remaining > 0) return '${firstItemName.trim()} +$remaining more';
      return firstItemName.trim();
    }
    return 'Order ${_shortId(order.orderNumber ?? order.id)}';
  }

  String _formatMoney(num? amount) {
    return '₹${(amount ?? 0).toStringAsFixed(2)}';
  }

  String _shortId(String? id) {
    if (id == null || id.length <= 8) return id ?? '-';
    return '${id.substring(0, 8)}...';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day-$month-$year $hour:$minute';
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
            color: Colors.black.withValues(alpha: 0.08),
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
                  _orderTitle(order),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _buildOrderStatusChip(order),
            ],
          ),

          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Order ID: ${_shortId(order.orderNumber ?? order.id)}",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Created: ${_formatDate(order.createdDate)}",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Payment: ${order.paymentStatus ?? '-'}",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _formatMoney(order.totalAmount),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColor.PrimaryColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _buildLineItems(order),

          const SizedBox(height: 16),

          _buildMiniTracker(_effectiveStatus(order)),

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
                        builder:
                            (_) => ComplaintsScreen(
                              orderId: order.id,
                              b2bId: order.businessId,
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
  Widget _buildLineItems(Content order) {
    if (order.orderItems.isEmpty) return const SizedBox();

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: order.orderItems.length,
        separatorBuilder:
            (_, __) => Divider(height: 1, color: Colors.grey.shade200),
        itemBuilder: (context, i) {
          final item = order.orderItems[i];

          return Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${i + 1}.',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productName ?? 'Item',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${item.productCode ?? '-'} • ${item.status ?? '-'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Qty ${item.quantity ?? 0}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _formatMoney(item.totalAmount),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColor.PrimaryColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMiniTracker(String status) {
    String normalized = status.toUpperCase();
    if (normalized == "CREATED" ||
        normalized == "PENDING") {
      normalized = "PLACED";
    } else if (normalized == "COMPLETED") {
      normalized = "DELIVERED";
    } else if (normalized == "PICKED_UP" || normalized == "IN_DELIVERY") {
      normalized = "OUT_FOR_DELIVERY";
    } else if (normalized == "READY" || normalized == "OUT_FOR_DELIVERY") {
      normalized = "OUT_FOR_DELIVERY";
    }

    if (normalized == "CONFIRMED") {
      normalized = "PREPARING";
    } else if (normalized == "READY_FOR_PICKUP") {
      normalized = "PREPARING";
    }

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
    final stages = ["PLACED", "PREPARING", "OUT_FOR_DELIVERY", "DELIVERED"];

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
              width:
                  currentIndex == -1
                      ? 0
                      : (MediaQuery.of(context).size.width *
                          ((currentIndex + 1) / stages.length)),
              decoration: BoxDecoration(
                color: softColor(normalized).withValues(alpha: 0.8),
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
                    color: active ? softColor(stages[i]) : Colors.grey.shade300,
                    boxShadow:
                        active
                            ? [
                              BoxShadow(
                                color: softColor(
                                  stages[i],
                                ).withValues(alpha: 0.5),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
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
      itemBuilder:
          (_, __) => Shimmer.fromColors(
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
