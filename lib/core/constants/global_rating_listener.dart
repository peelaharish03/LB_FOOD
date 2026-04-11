import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_basket/presentation/cubit/orders/orderHistory/orderHistory_cubit.dart';
import 'package:local_basket/presentation/cubit/orders/orderHistory/orderHistory_state.dart';
import 'rating_service.dart';

class GlobalRatingListener extends StatefulWidget {
  final Widget child;
  const GlobalRatingListener({super.key, required this.child});

  @override
  State<GlobalRatingListener> createState() => _GlobalRatingListenerState();
}

class _GlobalRatingListenerState extends State<GlobalRatingListener>
    with WidgetsBindingObserver {
  Timer? _timer;
  DateTime? _lastOrderCheckAt;
  static const Duration _minCheckInterval = Duration(seconds: 10);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startRatingCheckTimer();
    // Delayed first check to avoid showing over SplashScreen
    Future.delayed(const Duration(seconds: 5), _checkOrders);
  }

  void _startRatingCheckTimer() {
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _checkOrders());
  }

  // FIX: Made async to check login state before firing the API call.
  // Previously this ran every 60 seconds for ALL users — including guests —
  // generating 401 errors on every tick until the user logged in.
  Future<void> _checkOrders() async {
    if (!mounted) return;

    // FIX: Only poll order history when the user is actually logged in.
    // This prevents unnecessary 401 API calls for guest/unauthenticated users.
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'TOKEN') ?? '';
    if (token.isEmpty) {
      debugPrint('[GlobalRatingListener] Skipping order check — user not logged in');
      return;
    }

    final now = DateTime.now();
    final last = _lastOrderCheckAt;
    if (last != null && now.difference(last) < _minCheckInterval) {
      return;
    }
    _lastOrderCheckAt = now;
    debugPrint('[GlobalRatingListener] Triggering order check');

    if (!mounted) return;
    final cubit = context.read<OrderHistoryCubit>();
    cubit.fetchCart(0, 20, '', context);
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkOrders();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OrderHistoryCubit, OrderHistoryState>(
      listener: (context, state) {
        if (state is OrderHistoryLoaded) {
          final orders = state.orders.data?.content ?? [];
          final delivered = orders
              .where((o) => (o.orderStatus ?? '').toUpperCase() == 'DELIVERED')
              .length;
          debugPrint(
              '[GlobalRatingListener] Orders loaded: ${orders.length}, delivered: $delivered');
          RatingService().checkAndShowRatingPopup(
            context: context,
            orders: orders,
          );
        }
      },
      child: widget.child,
    );
  }
}
