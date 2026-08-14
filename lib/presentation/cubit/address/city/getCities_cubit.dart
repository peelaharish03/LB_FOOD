import 'package:local_basket/components/custom_snackbar.dart';
import 'package:local_basket/core/network/network_service.dart';
import 'package:local_basket/domain/usecase/address/city/getCities_usecase.dart';
import 'package:local_basket/presentation/cubit/address/city/getCities_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GetCitiesCubit extends Cubit<GetCitiesState> {
  final GetCitiesUseCase useCase;
  final NetworkService networkService;

  GetCitiesCubit(this.useCase, this.networkService) : super(GetCitiesInitial());

  Future<void> getCities(context, [String? stateCode]) async {
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
      emit(GetCitiesLoading());
      try {
        final result = await useCase.call(stateCode);
        emit(GetCitiesSuccess(result, stateCode));
      } catch (e) {
        print(e);
        emit(GetCitiesFailure(e.toString()));
      }
    }
  }
}
