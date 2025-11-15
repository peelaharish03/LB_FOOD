abstract class CreateComplaintState {}

class CreateComplaintInitial extends CreateComplaintState {}

class CreateComplaintLoading extends CreateComplaintState {}

class CreateComplaintSuccess extends CreateComplaintState {
  final dynamic data;
  CreateComplaintSuccess(this.data);
}

class CreateComplaintFailure extends CreateComplaintState {
  final String error;
  CreateComplaintFailure(this.error);
}
