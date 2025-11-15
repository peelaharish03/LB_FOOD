import 'package:local_basket/components/custom_snackbar.dart';
import 'package:local_basket/core/network/network_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_basket/domain/usecase/orders/reOrder/reOrder_usecase.dart';
import 'reOrder_state.dart';

class ReOrderCubit extends Cubit<ReOrderState> {
  final ReOrderUseCase usecase;
  final NetworkService networkService;

  ReOrderCubit(this.usecase, this.networkService) : super(ReOrderInitial());

  Future<void> reOrder(dynamic payload, context) async {
    bool isConnected = await networkService.hasInternetConnection();
    print(isConnected);
    if (!isConnected) {
      print("No Internet Connection");
      CustomSnackbars.showErrorSnack(
        context: context,
        title: 'Alert',
        message: 'Please check Internet Connection',
      );
      return;
    } else {
      emit(ReOrderLoading());
      try {
        final result = await usecase(payload);
        emit(ReOrderSuccess(reOrderModel: result));
      } catch (e) {
        emit(ReOrderFailure(message: e.toString()));
      }
    }
  }
}
