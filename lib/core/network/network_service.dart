import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:local_basket/core/constants/api_constants.dart';

class NetworkService {
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
  final StreamController<bool> _connectionChangeController =
      StreamController<bool>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  NetworkService() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      result,
    ) async {
      _connectionChangeController.add(await hasInternetConnection());
    });
  }

  Stream<bool> get onConnectivityChanged => _connectionChangeController.stream;

  Future<bool> hasInternetConnection() async {
    final List<ConnectivityResult> connectivityResult;

    try {
      connectivityResult = await _connectivity.checkConnectivity();
    } catch (e) {
      debugPrint('[NetworkService] connectivity check failed: $e');
      return true;
    }

    if (!_hasNetworkInterface(connectivityResult)) {
      debugPrint('[NetworkService] no network interface: $connectivityResult');
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
        '[NetworkService] connectivity=$connectivityResult '
        'reachability=$hasInternetAccess',
      );
    } catch (e) {
      debugPrint('[NetworkService] reachability check failed: $e');
    }
  }

  bool _hasNetworkInterface(List<ConnectivityResult> results) {
    return results.any((result) => result != ConnectivityResult.none);
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _connectionChangeController.close();
  }
}
