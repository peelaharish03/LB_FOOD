import 'package:local_basket/components/custom_snackbar.dart';
import 'package:local_basket/core/network/network_service.dart';
import 'package:local_basket/domain/usecase/orders/orderHistory/orderHistory_usecase.dart';
import 'package:local_basket/presentation/cubit/orders/orderHistory/orderHistory_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OrderHistoryCubit extends Cubit<OrderHistoryState> {
  final OrderHistoryUseCase useCase;
  final NetworkService networkService;

  OrderHistoryCubit(this.useCase, this.networkService)
    : super(OrderHistoryInitial());

  Future<void> fetchCart(
    int page,
    int size,
    String searchQuery,
    context,
  ) async {
    bool isConnected = await networkService.hasInternetConnection();
    print(isConnected);
    if (!isConnected) {
      print("No Internet Connection");
      CustomSnackbars.showErrorSnack(
        context: context,
        title: 'Alert',
        message: 'Please check Internet Connection',
      );
      emit(OrderHistoryError('Please check Internet Connection', page: page));
      return;
    } else {
      emit(OrderHistoryLoading(page: page));
      try {
        final cart = await useCase.execute(page, size, searchQuery);
        emit(
          OrderHistoryLoaded(
            cart,
            page: page,
            size: size,
            searchQuery: searchQuery,
          ),
        );
      } catch (e) {
        print('Error fetching order history: $e');
        emit(OrderHistoryError(e.toString(), page: page));
      }
    }
  }
}
