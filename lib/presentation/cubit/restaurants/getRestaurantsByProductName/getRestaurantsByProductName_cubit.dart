import 'package:local_basket/domain/usecase/restaurants/getRestaurantsByProductName/getRestaurantsByProductName_usecase.dart';
import 'package:local_basket/core/constants/global_exception_handler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'getRestaurantsByProductName_state.dart';

class GetRestaurantsByProductNameCubit
    extends Cubit<GetRestaurantsByProductNameState> {
  final GetRestaurantsByProductNameUseCase useCase;

  GetRestaurantsByProductNameCubit(this.useCase)
      : super(GetRestaurantsByProductNameInitial());

  Future<void> fetchRestaurantsByProductName(
      Map<String, dynamic> params) async {
    print(params);
    try {
      emit(GetRestaurantsByProductNameLoading());
      final result = await useCase(params);
      emit(GetRestaurantsByProductNameSuccess(result));
    } catch (e) {
      print(e);
      emit(GetRestaurantsByProductNameFailure(friendlyErrorMessage(e)));
    }
  }
}
