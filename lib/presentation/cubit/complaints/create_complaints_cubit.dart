import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_basket/domain/usecase/complaints/create_complaints_usecase.dart';
import 'package:local_basket/presentation/cubit/complaints/create_complaints_state.dart';

class CreateComplaintCubit extends Cubit<CreateComplaintState> {
  final CreateComplaintUseCase createComplaintUseCase;

  CreateComplaintCubit({required this.createComplaintUseCase})
      : super(CreateComplaintInitial());

  Future<void> createComplaint(Map<String, dynamic> payload) async {
    emit(CreateComplaintLoading());

    try {
      final response = await createComplaintUseCase(payload);
      emit(CreateComplaintSuccess(response));
    } catch (e) {
      emit(CreateComplaintFailure(e.toString()));
    }
  }
}
