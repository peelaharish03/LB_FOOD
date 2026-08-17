import 'package:local_basket/domain/usecase/authentication/deleteAccount_usecase.dart';
import 'package:local_basket/core/constants/global_exception_handler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'deleteAccount_state.dart';

class DeleteAccountCubit extends Cubit<DeleteAccountState> {
  final DeleteAccountUseCase deleteAccountUseCase;

  DeleteAccountCubit(this.deleteAccountUseCase) : super(DeleteAccountInitial());

  Future<void> deleteAccount() async {
    emit(DeleteAccountLoading());
    try {
      final response = await deleteAccountUseCase();
      emit(DeleteAccountSuccess(response));
    } catch (e) {
      emit(DeleteAccountFailure(friendlyErrorMessage(e)));
    }
  }
}
