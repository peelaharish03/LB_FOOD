import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_basket/domain/usecase/offers/restaurant_offers/restaurant_offers_usecase.dart';
import 'package:local_basket/presentation/cubit/offers/restaurant_offers/get_restaurant_offers/restaurant_offers_state.dart';

class RestaurantOffersCubit extends Cubit<RestaurantOffersState> {
  final RestaurantOffersUseCase getRestaurantOffersUseCase;

  RestaurantOffersCubit( this.getRestaurantOffersUseCase)
      : super(RestaurantOffersInitial());

  Future<void> fetchRestaurantOffers() async {
    try {
      emit(RestaurantOffersLoading());
      final offers = await getRestaurantOffersUseCase.call();
      emit(RestaurantOffersLoaded(offers: offers));
    } catch (e) {
      emit(RestaurantOffersError(message: e.toString()));
    }
  }
}
