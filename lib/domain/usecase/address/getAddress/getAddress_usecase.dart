import 'package:flutter/foundation.dart';
import 'package:local_basket/data/model/address/getAddress/getAddress_model.dart';
import 'package:local_basket/domain/repository/address/getAddress/getAddress_repository.dart';

class GetAddressUseCase {
  final GetAddressRepository repository;

  GetAddressUseCase({required this.repository});

  static const String _tag = '[GetAddress][UseCase]';

  Future<GetAddressModel> call() async {
    debugPrint('$_tag ➡️ execute');
    final result = await repository.getAddress();
    debugPrint('$_tag ⬅️ done → content.length=${result.content.length}');
    return result;
  }
}
