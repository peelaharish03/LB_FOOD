import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_basket/components/custom_topbar.dart';
import 'package:local_basket/core/constants/colors.dart';
import 'package:local_basket/core/injection.dart';
import 'package:local_basket/presentation/cubit/notifications/notifications_cubit.dart';
import 'package:local_basket/presentation/cubit/notifications/notifications_state.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<NotificationsCubit>()..fetchNotifications(),
      child: const _NotificationsView(),
    );
  }
}

class _NotificationsView extends StatefulWidget {
  const _NotificationsView();

  @override
  State<_NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<_NotificationsView> {
  @override
  Widget build(BuildContext context) {
    final cubit = context.read<NotificationsCubit>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Notifications',
        showBackButton: true,
        actions: [
          BlocBuilder<NotificationsCubit, NotificationsState>(
            builder: (_, state) {
              final isLoading = state is ClearNotificationsLoading;
              final hasItems = state is NotificationsLoaded &&
                      state.notifications.data!.content.isNotEmpty ??
                  false;

              return TextButton.icon(
                onPressed: (!hasItems || isLoading)
                    ? null
                    : () => cubit.clearNotifications(),
                icon: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Icon(Icons.delete_sweep_rounded,
                        color: Colors.white),
                label: const Text(
                  'Clear All',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<NotificationsCubit, NotificationsState>(
        builder: (_, state) {
          if (state is NotificationsInitial || state is NotificationsLoading) {
            return _loadingList();
          }

          if (state is NotificationsError) {
            return _errorView(state.message);
          }

          if (state is NotificationsLoaded) {
            final List<dynamic> items = state.notifications.data?.content ?? [];

            if (items.isEmpty) return _emptyView();

            return _notificationsList(items, cubit);
          }

          return const SizedBox();
        },
      ),
    );
  }

  // --------------------------------------------------------
  // CLEAN NEW PROFESSIONAL UI
  // --------------------------------------------------------

  /// 🔹 List UI
  Widget _notificationsList(List<dynamic> items, NotificationsCubit cubit) {
    return RefreshIndicator(
      onRefresh: () async => cubit.fetchNotifications(),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, index) {
          final n = items[index];
          return _notificationCard(n);
        },
      ),
    );
  }

  /// 🔹 Clean modern card
  Widget _notificationCard(dynamic n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon Box
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColor.PrimaryColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _iconForType(n.type ?? ""),
              color: AppColor.PrimaryColor,
              size: 22,
            ),
          ),

          const SizedBox(width: 14),

          // Texts
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  n.message ?? "Notification",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                if ((n.type ?? "").isNotEmpty)
                  Text(
                    n.type!,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColor.PrimaryColor.withOpacity(0.85),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.access_time_rounded,
                        size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(n.creationTime),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------
  // EMPTY VIEW
  // --------------------------------------------------------
  Widget _emptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 120),
        child: Column(
          children: [
            Icon(Icons.notifications_none_rounded,
                size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              "No Notifications",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              "You're all caught up!",
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------
  // LOADING SHIMMER
  // --------------------------------------------------------
  Widget _loadingList() => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        itemBuilder: (_, __) => _shimmerCard(),
      );

  Widget _shimmerCard() => Container(
        height: 80,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(14),
        ),
      );

  // --------------------------------------------------------
  // ERROR VIEW
  // --------------------------------------------------------
  Widget _errorView(String message) {
    return Center(
      child: Text(
        "Error: $message",
        style: const TextStyle(color: Colors.black54),
      ),
    );
  }

  // --------------------------------------------------------
  // ICON MAPPING
  // --------------------------------------------------------
  IconData _iconForType(String type) {
    final t = type.toLowerCase();

    if (t.contains('order')) return Icons.receipt_long_rounded;
    if (t.contains('offer') || t.contains('promo')) {
      return Icons.local_offer_rounded;
    }
    if (t.contains('payment')) return Icons.payments_rounded;

    return Icons.notifications_rounded;
  }

  // --------------------------------------------------------
  // CLEAN HUMAN-FRIENDLY TIME FORMAT
  // --------------------------------------------------------
  String _formatTime(DateTime? dt) {
    if (dt == null) return "";
    final diff = DateTime.now().difference(dt);

    if (diff.inSeconds < 60) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    if (diff.inDays < 7) return "${diff.inDays}d ago";

    return "${dt.day}/${dt.month}/${dt.year}";
  }
}
