import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:local_basket/components/custom_snackbar.dart';
import 'package:local_basket/components/custom_topbar.dart';
import 'package:local_basket/core/constants/colors.dart';
import 'package:local_basket/core/injection.dart';
import 'package:local_basket/data/model/pools/pools_model.dart';
import 'package:local_basket/presentation/cubit/pools/joinPool/joinPool_cubit.dart';
import 'package:local_basket/presentation/cubit/pools/joinPool/joinPool_state.dart';
import 'package:local_basket/presentation/cubit/pools/pools_cubit.dart';
import 'package:local_basket/presentation/cubit/pools/pools_state.dart';

class PoolScreen extends StatelessWidget {
  const PoolScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<PoolsCubit>()..fetchPools()),
        BlocProvider(create: (_) => sl<JoinPoolCubit>()),
      ],
      child: const _PoolView(),
    );
  }
}

class _PoolView extends StatefulWidget {
  const _PoolView();

  @override
  State<_PoolView> createState() => _PoolViewState();
}

class _PoolViewState extends State<_PoolView> {
  Timer? _timer;
  Timer? _pollTimer;
  DateTime _now = DateTime.now();

  final Set<String> _joinedPoolIds = {};
  String? _joiningPoolId;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
    // Poll in the background so pools added/updated by others while the
    // user is on this screen show up without them pulling to refresh.
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) context.read<PoolsCubit>().refreshPoolsSilently();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  String _formatCountdown(Duration d) {
    if (d.isNegative) return '00:00';
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  bool _isJoined(PoolItem pool) =>
      (pool.joinedByCurrentUser ?? false) || _joinedPoolIds.contains(pool.id);

  void _participate(PoolItem pool) {
    final poolId = pool.id;
    if (poolId == null || poolId.isEmpty) return;
    if (_isJoined(pool) || _joiningPoolId != null) return;

    setState(() => _joiningPoolId = poolId);
    context.read<JoinPoolCubit>().joinPool(poolId);
  }

  void _showCelebration(String poolName) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Celebration',
      barrierColor: Colors.black.withOpacity(0.55),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) => _CelebrationOverlay(poolName: poolName),
      transitionBuilder: (_, animation, __, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  void _showCompletedDetails(PoolItem pool) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(pool.name ?? 'Pool'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if ((pool.description ?? '').isNotEmpty) ...[
                  const Text(
                    'Description',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(pool.description!),
                  const SizedBox(height: 12),
                ],
                const Text(
                  'Participants',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text('${pool.participantCount ?? 0}'),
                const SizedBox(height: 12),
                const Text(
                  'Winner',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(pool.winnerUserId ?? 'Not yet selected'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<JoinPoolCubit, JoinPoolState>(
      listener: (context, state) {
        if (state is JoinPoolSuccess) {
          setState(() {
            _joinedPoolIds.add(state.poolId);
            _joiningPoolId = null;
          });
          final pools = context.read<PoolsCubit>().state;
          final poolName =
              pools is PoolsLoaded
                  ? pools.pools.content
                      .firstWhere(
                        (p) => p.id == state.poolId,
                        orElse: () => PoolItem(),
                      )
                      .name
                  : null;
          context.read<PoolsCubit>().fetchPools();
          _showCelebration(poolName ?? 'the pool');
        } else if (state is JoinPoolFailure) {
          setState(() => _joiningPoolId = null);
          CustomSnackbars.showErrorSnack(
            context: context,
            title: 'Failed',
            message:
                state.message.isEmpty
                    ? 'Could not join the pool. Please try again.'
                    : state.message,
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColor.White,
        appBar: const CustomAppBar(title: 'Pool', showBackButton: true),
        body: BlocBuilder<PoolsCubit, PoolsState>(
        builder: (context, state) {
          if (state is PoolsInitial || state is PoolsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is PoolsError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => context.read<PoolsCubit>().fetchPools(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is PoolsLoaded) {
            final pools = state.pools.content;
            if (pools.isEmpty) {
              return const Center(child: Text('No pools available'));
            }
            return RefreshIndicator(
              onRefresh: () async => context.read<PoolsCubit>().fetchPools(),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: pools.length,
                itemBuilder: (context, index) => _poolCard(pools[index]),
              ),
            );
          }

          return const SizedBox();
        },
        ),
      ),
    );
  }

  Widget _poolCard(PoolItem pool) {
    final status = pool.apiStatus ?? pool.statusAt(_now);
    final isActive = status == PoolStatus.active;
    final isCompleted = status == PoolStatus.completed;
    final isUpcoming = status == PoolStatus.upcoming;
    final timeFormat = DateFormat('hh:mm a');
    final start = pool.startDateTime;
    final end = pool.endDateTime;

    final isJoined = _isJoined(pool);
    final isJoining = _joiningPoolId == pool.id;

    return GestureDetector(
      onTap: isCompleted ? () => _showCompletedDetails(pool) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient:
              isActive
                  ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColor.PrimaryColor,
                      Color.lerp(AppColor.PrimaryColor, Colors.black, 0.35)!,
                    ],
                  )
                  : null,
          color:
              isActive
                  ? null
                  : (isUpcoming ? Colors.grey.shade100 : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border:
              isActive
                  ? null
                  : Border.all(color: Colors.grey.shade200, width: 1),
          boxShadow: [
            BoxShadow(
              color:
                  isActive
                      ? AppColor.PrimaryColor.withOpacity(0.35)
                      : Colors.black12,
              blurRadius: isActive ? 18 : 8,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    pool.name ?? 'Pool',
                    style: TextStyle(
                      fontSize: isActive ? 17 : 16,
                      fontWeight: FontWeight.w700,
                      color:
                          isActive
                              ? Colors.white
                              : (isUpcoming
                                  ? Colors.grey.shade600
                                  : Colors.black),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                isActive ? _liveBadge() : _statusBadge(status),
              ],
            ),
            const SizedBox(height: 6),
            if (start != null && end != null)
              Text(
                '${timeFormat.format(start)} - ${timeFormat.format(end)}',
                style: TextStyle(
                  fontSize: 13,
                  color: isActive ? Colors.white70 : Colors.grey[600],
                ),
              ),
            const SizedBox(height: 12),
            if (isActive && end != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      size: 20,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatCountdown(end.difference(_now)),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'left',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (isCompleted)
              Row(
                children: [
                  Icon(
                    Icons.emoji_events_outlined,
                    size: 16,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Tap to view result',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      (isUpcoming || isJoined || isJoining)
                          ? null
                          : () => _participate(pool),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isActive
                            ? (isJoined ? Colors.white : Colors.white)
                            : (isJoined ? Colors.green : AppColor.PrimaryColor),
                    disabledBackgroundColor:
                        isActive
                            ? Colors.white.withOpacity(isJoined ? 1 : 0.55)
                            : (isJoined ? Colors.green : Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: isActive ? 0 : 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child:
                      isJoining
                          ? SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: isActive ? AppColor.PrimaryColor : Colors.white,
                            ),
                          )
                          : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (isJoined) ...[
                                Icon(
                                  Icons.check_circle,
                                  size: 18,
                                  color: isActive ? Colors.green : Colors.white,
                                ),
                                const SizedBox(width: 6),
                              ],
                              Text(
                                isUpcoming
                                    ? 'Not Started'
                                    : isJoined
                                    ? 'Joined'
                                    : 'Participate',
                                style: TextStyle(
                                  color:
                                      isActive
                                          ? (isJoined
                                              ? Colors.green
                                              : AppColor.PrimaryColor)
                                          : Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _liveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _LiveDot(color: Colors.white),
          const SizedBox(width: 6),
          const Text(
            'LIVE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(PoolStatus status) {
    late Color color;
    late String label;
    switch (status) {
      case PoolStatus.upcoming:
        color = Colors.grey;
        label = 'Upcoming';
        break;
      case PoolStatus.active:
        color = Colors.green;
        label = 'Live';
        break;
      case PoolStatus.completed:
        color = Colors.blueGrey;
        label = 'Closed';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _LiveDot extends StatefulWidget {
  final Color color;
  const _LiveDot({required this.color});

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final scale = 0.85 + (_controller.value * 0.5);
        return Stack(
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scale: scale,
              child: Opacity(
                opacity: (1 - _controller.value) * 0.6,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: widget.color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
            ),
          ],
        );
      },
    );
  }
}

class _Spark {
  final double angle;
  final double distance;
  final double size;
  final double delay;
  final Color color;

  _Spark({
    required this.angle,
    required this.distance,
    required this.size,
    required this.delay,
    required this.color,
  });
}

class _CelebrationOverlay extends StatefulWidget {
  final String poolName;

  const _CelebrationOverlay({required this.poolName});

  @override
  State<_CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<_CelebrationOverlay>
    with SingleTickerProviderStateMixin {
  static const _sparkColors = [
    Color(0xFFFFC107),
    Color(0xFFFF7043),
    Color(0xFF66BB6A),
    Color(0xFF29B6F6),
    Color(0xFFEC407A),
  ];

  late final AnimationController _controller;
  late final List<_Spark> _sparks;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();

    final random = Random();
    _sparks = List.generate(24, (i) {
      final angle = (i / 24) * 2 * pi + random.nextDouble() * 0.2;
      final distance = 70 + random.nextDouble() * 60;
      final size = 6 + random.nextDouble() * 8;
      final delay = random.nextDouble() * 0.3;
      return _Spark(
        angle: angle,
        distance: distance,
        size: size,
        delay: delay,
        color: _sparkColors[i % _sparkColors.length],
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildSpark(_Spark s) {
    final t = ((_controller.value - s.delay) / (1 - s.delay)).clamp(0.0, 1.0);
    final eased = Curves.easeOut.transform(t);
    final opacity =
        t < 0.15 ? t / 0.15 : (1 - ((t - 0.15) / 0.85)).clamp(0.0, 1.0);
    final dx = cos(s.angle) * s.distance * eased;
    final dy = sin(s.angle) * s.distance * eased;

    return Opacity(
      opacity: opacity,
      child: Transform.translate(
        offset: Offset(dx, dy),
        child: Transform.rotate(
          angle: eased * pi,
          child: Icon(Icons.auto_awesome, size: s.size, color: s.color),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    final scale = Curves.elasticOut.transform(_controller.value.clamp(0.0, 1.0));
    return Transform.scale(
      scale: scale,
      child: Container(
        width: 260,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.celebration_rounded,
              size: 56,
              color: Color(0xFFFF7A45),
            ),
            const SizedBox(height: 14),
            const Text(
              'Successfully Participated!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              "You've joined ${widget.poolName}. Please wait a while for the result.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.PrimaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Got it',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return SizedBox(
              width: 300,
              height: 340,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ..._sparks.map(_buildSpark),
                  _buildCard(context),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
