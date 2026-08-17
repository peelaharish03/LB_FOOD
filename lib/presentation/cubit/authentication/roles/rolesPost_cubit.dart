import 'package:local_basket/components/custom_snackbar.dart';
import 'package:local_basket/core/constants/global_exception_handler.dart';
import 'package:local_basket/core/network/network_service.dart';
import 'package:local_basket/domain/usecase/authentication/rolesPost_usecase.dart';
import 'package:local_basket/presentation/cubit/authentication/roles/rolesPost_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RolePostCubit extends Cubit<RolePostState> {
  final RolePostUsecase rolePostUsecase;
  final NetworkService networkService;

  RolePostCubit(this.rolePostUsecase, this.networkService) : super(RolePostInitial());

  Future<void> postRole({String? role, context} ) async {
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
    }
    emit(RolePostLoading());
    try {
      final result = await rolePostUsecase.call(role);
      emit(RolePostSuccess(result));
    } catch (e) {
      emit(RolePostFailure(friendlyErrorMessage(e)));
    }
  }
}
