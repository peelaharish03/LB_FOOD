import 'package:local_basket/components/custom_snackbar.dart';
import 'package:local_basket/core/network/network_service.dart';
import 'package:local_basket/domain/usecase/address/state/getStates_usecase.dart';
import 'package:local_basket/presentation/cubit/address/state/getStates_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GetStatesCubit extends Cubit<GetStatesState> {
  final GetStatesUseCase useCase;
  final NetworkService networkService;

  GetStatesCubit(this.useCase, this.networkService) : super(GetStatesInitial());

  Future<void> getStates(context) async {
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
      emit(GetStatesLoading());
      try {
        final result = await useCase.call();
        emit(GetStatesSuccess(result));
      } catch (e) {
        print(e);
        emit(GetStatesFailure(e.toString()));
      }
    }
  }
}
