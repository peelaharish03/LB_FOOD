import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:local_basket/core/constants/api_constants.dart';
import 'dart:async';

class NetworkCubit extends Cubit<bool> {
  final Connectivity _connectivity = Connectivity();
  final InternetConnection _internetConnection =
      InternetConnection.createInstance(
        customCheckOptions: [
          InternetCheckOption(
            uri: Uri.parse(baseUrl2),
            timeout: const Duration(seconds: 5),
            responseStatusFn: (response) => response.statusCode < 500,
          ),
        ],
      );
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  NetworkCubit() : super(true) {
    _subscription = _connectivity.onConnectivityChanged.listen((result) async {
      bool isConnected = await _checkInternet(result);
      emit(isConnected);
    });
  }

  Future<bool> _checkInternet(
    List<ConnectivityResult> connectivityResult,
  ) async {
    if (!_hasNetworkInterface(connectivityResult)) {
      debugPrint('[NetworkCubit] no network interface: $connectivityResult');
      return false;
    }

    unawaited(_logReachabilityResult(connectivityResult));
    return true;
  }

  Future<void> _logReachabilityResult(
    List<ConnectivityResult> connectivityResult,
  ) async {
    try {
      final hasInternetAccess = await _internetConnection.hasInternetAccess
          .timeout(const Duration(seconds: 6), onTimeout: () => false);
      debugPrint(
        '[NetworkCubit] connectivity=$connectivityResult '
        'reachability=$hasInternetAccess',
      );
    } catch (e) {
      debugPrint('[NetworkCubit] reachability check failed: $e');
    }
  }

  bool _hasNetworkInterface(List<ConnectivityResult> results) {
    return results.any((result) => result != ConnectivityResult.none);
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
