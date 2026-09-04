import 'package:flutter/foundation.dart';
import 'package:local_basket/components/custom_snackbar.dart';
import 'package:local_basket/core/constants/global_exception_handler.dart';
import 'package:local_basket/core/network/network_service.dart';
import 'package:local_basket/domain/usecase/address/getAddress/getAddress_usecase.dart';
import 'package:local_basket/presentation/cubit/address/getAddress/getAddress_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GetAddressCubit extends Cubit<GetAddressState> {
  final GetAddressUseCase getAddressUseCase;
  final NetworkService networkService;

  GetAddressCubit(this.getAddressUseCase, this.networkService)
      : super(GetAddressInitial());

  static const String _tag = '[GetAddress][Cubit]';

  Future<void> fetchAddress(context) async {
    final stopwatch = Stopwatch()..start();
    debugPrint('$_tag ▶️ fetchAddress() called');

    final bool isConnected = await networkService.hasInternetConnection();
    debugPrint('$_tag    hasInternetConnection = $isConnected');

    if (!isConnected) {
      debugPrint('$_tag ⛔ aborting → no internet connection');
      CustomSnackbars.showErrorSnack(
        context: context,
        title: 'Alert',
        message: 'Please check Internet Connection',
      );
      return;
    }

    debugPrint('$_tag    emit → GetAddressLoading');
    emit(GetAddressLoading());
    try {
      final result = await getAddressUseCase();
      stopwatch.stop();
      debugPrint(
        '$_tag ✅ emit → GetAddressSuccess '
        '(${result.content.length} address(es), ${stopwatch.elapsedMilliseconds}ms)',
      );
      emit(GetAddressSuccess(result));
    } catch (e, st) {
      stopwatch.stop();
      final message = friendlyErrorMessage(e);
      debugPrint(
        '$_tag ❌ emit → GetAddressFailure "$message" '
        '(${stopwatch.elapsedMilliseconds}ms) raw=$e',
      );
      debugPrint('$_tag    stack: $st');
      emit(GetAddressFailure(message));
    }
  }
}
