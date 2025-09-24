import 'package:dio/dio.dart';
import 'package:local_basket/core/network/dio_client.dart';
import 'package:local_basket/core/network/network_cubit.dart';
import 'package:local_basket/core/network/network_service.dart';
import 'package:local_basket/data/datasource/address/defaultAddress/get/getDefaultAddress_dataSource.dart';
import 'package:local_basket/data/datasource/address/defaultAddress/post/defaultAddress_dataSource.dart';
import 'package:local_basket/data/datasource/address/deleteAddress/deleteAddress_dataSource.dart';
import 'package:local_basket/data/datasource/address/getAddress/getAddress_dataSource.dart';
import 'package:local_basket/data/datasource/address/saveAddress/saveAddress_dataSource.dart';
import 'package:local_basket/data/datasource/authentication/current_customer_remote_data_source.dart';
import 'package:local_basket/data/datasource/authentication/deleteAccount_dataSource.dart';
import 'package:local_basket/data/datasource/authentication/rolesPost_dataSource.dart';
import 'package:local_basket/data/datasource/authentication/signin_remote_data_source.dart';
import 'package:local_basket/data/datasource/authentication/signup_remote_data_source.dart';
import 'package:local_basket/data/datasource/authentication/trigger_otp_remote_data_source.dart';
import 'package:local_basket/data/datasource/authentication/update_current_customer_dataSource.dart';
import 'package:local_basket/data/datasource/cart/clearCart/clearCart_dataSource.dart';
import 'package:local_basket/data/datasource/cart/createCart/createCart_dataSource.dart';
import 'package:local_basket/data/datasource/cart/getCart/getCart_dataSource.dart';
import 'package:local_basket/data/datasource/cart/productsAddToCart/productsAddtoCart_dataSource.dart';
import 'package:local_basket/data/datasource/cart/updateCartItems/updateCartItems_dataSource.dart';
import 'package:local_basket/data/datasource/location/location_remotedatasource.dart';
import 'package:local_basket/data/datasource/offers/restaurant_offers/restaurant_offers_dataSource.dart';
import 'package:local_basket/data/datasource/offers/restaurant_offers/validate_offer_dataSource.dart';
import 'package:local_basket/data/datasource/orders/createOrder/createOrder_dataSource.dart';
import 'package:local_basket/data/datasource/orders/orderHistory/orderHistory_dataSource.dart';
import 'package:local_basket/data/datasource/orders/reOrder/reOrder_dataSource.dart';
import 'package:local_basket/data/datasource/payment/payment_dataSource.dart';
import 'package:local_basket/data/datasource/restaurants/getMenuByRestaurantId/getMenuByRestaurantId_dataSource.dart';
import 'package:local_basket/data/datasource/restaurants/getNearbyRestaurants/getNearByrestarants_dataSource.dart';
import 'package:local_basket/data/datasource/restaurants/getRestaurantsByProductName/getRestaurantsByProductName_dataSource.dart';
import 'package:local_basket/data/datasource/restaurants/guestMenuByRestaurantId/guestMenuByRestaurantId_dataSource.dart';
import 'package:local_basket/data/datasource/restaurants/guestNearbyRestaurants/guestNearbyRestaurants_dataSource.dart';
import 'package:local_basket/data/repositoryImpl/address/defaultAddress/get/getDefaultAddress_repoImpl.dart';
import 'package:local_basket/data/repositoryImpl/address/defaultAddress/post/defaultAddress_dataSource.dart';
import 'package:local_basket/data/repositoryImpl/address/deleteAddress/deleteAddress_repoImpl.dart';
import 'package:local_basket/data/repositoryImpl/address/getAddress/getAddress_repoImpl.dart';
import 'package:local_basket/data/repositoryImpl/address/saveAddress/saveAddress_repoImpl.dart';
import 'package:local_basket/data/repositoryImpl/authentication/current_customer_repository_impl.dart';
import 'package:local_basket/data/repositoryImpl/authentication/deleteAccount_repoImpl.dart';
import 'package:local_basket/data/repositoryImpl/authentication/rolesPost_repoImpl.dart';
import 'package:local_basket/data/repositoryImpl/authentication/signin_repository_impl.dart';
import 'package:local_basket/data/repositoryImpl/authentication/signup_repository_impl.dart';
import 'package:local_basket/data/repositoryImpl/authentication/trigger_otp_repository_impl.dart';
import 'package:local_basket/data/repositoryImpl/authentication/update_current_customer_repoImpl.dart';
import 'package:local_basket/data/repositoryImpl/cart/clearCart/clearCart_repoImpl.dart';
import 'package:local_basket/data/repositoryImpl/cart/createCart/createCart_repoImpl.dart';
import 'package:local_basket/data/repositoryImpl/cart/getCart/getCart_repoImpl.dart';
import 'package:local_basket/data/repositoryImpl/cart/productsAddToCart/productsAddtoCart_repoImpl.dart';
import 'package:local_basket/data/repositoryImpl/cart/updateCartItems/updateCartItems_repoImpl.dart';
import 'package:local_basket/data/repositoryImpl/location/location_repoImpl.dart';
import 'package:local_basket/data/repositoryImpl/offers/restaurant_offers/restaurant_offers_repoImpl.dart';
import 'package:local_basket/data/repositoryImpl/offers/restaurant_offers/validate_offer_repoImpl.dart';
import 'package:local_basket/data/repositoryImpl/orders/createOrder/createOrder_repoImpl.dart';
import 'package:local_basket/data/repositoryImpl/orders/orderHistory/orderHistory_repoImpl.dart';
import 'package:local_basket/data/repositoryImpl/orders/reOrder/reOrder_repoImpl.dart';
import 'package:local_basket/data/repositoryImpl/payment/payment_repoImpl.dart';
import 'package:local_basket/data/repositoryImpl/restaurants/getMenuByRestaurantId/getMenuByRestaurantId_repoImpl.dart';
import 'package:local_basket/data/repositoryImpl/restaurants/getNearbyRestaurants/getNearByrestarants_repoImpl.dart';
import 'package:local_basket/data/repositoryImpl/restaurants/getRestaurantsByProductName/getRestaurantsByProductName_repoImpl.dart';
import 'package:local_basket/data/repositoryImpl/restaurants/guestMenuByRestaurantId/guestMenuByRestaurantId_repoImpl.dart';
import 'package:local_basket/data/repositoryImpl/restaurants/guestNearbyRestaurants/guestNearbyRestaurants_repoImpl.dart';
import 'package:local_basket/domain/repository/address/defaultAddress/get/getDefaultAddress_repository.dart';
import 'package:local_basket/domain/repository/address/defaultAddress/post/defaultAddress_repository.dart';
import 'package:local_basket/domain/repository/address/deleteAddress/deleteAddress_repository.dart';
import 'package:local_basket/domain/repository/address/getAddress/getAddress_repository.dart';
import 'package:local_basket/domain/repository/address/saveAddress/saveAddress_repository.dart';
import 'package:local_basket/domain/repository/authentication/current_customer_repository.dart';
import 'package:local_basket/domain/repository/authentication/deleteAccount_repository.dart';
import 'package:local_basket/domain/repository/authentication/rolesPost_repository.dart';
import 'package:local_basket/domain/repository/authentication/signin_repository.dart';
import 'package:local_basket/domain/repository/authentication/signup_repository.dart';
import 'package:local_basket/domain/repository/authentication/trigger_otp_repository.dart';
import 'package:local_basket/domain/repository/authentication/update_current_customer_repository.dart';
import 'package:local_basket/domain/repository/cart/clearCart/clearCart_repository.dart';
import 'package:local_basket/domain/repository/cart/createCart/createCart_repository.dart';
import 'package:local_basket/domain/repository/cart/getCart/getCart_repository.dart';
import 'package:local_basket/domain/repository/cart/productsAddToCart/productsAddtoCart_repository.dart';
import 'package:local_basket/domain/repository/cart/updateCartItems/updateCartItems_repository.dart';
import 'package:local_basket/domain/repository/location/location_repo.dart';
import 'package:local_basket/domain/repository/offers/restaurant_offers/restaurant_offers_repository.dart';
import 'package:local_basket/domain/repository/offers/restaurant_offers/validate_offer_repository.dart';
import 'package:local_basket/domain/repository/orders/createOrder/createOrder_repository.dart';
import 'package:local_basket/domain/repository/orders/orderHistory/orderHistory_repository.dart';
import 'package:local_basket/domain/repository/orders/reOrder/reOrder_repository.dart';
import 'package:local_basket/domain/repository/payment/payment_repository.dart';
import 'package:local_basket/domain/repository/restaurants/getMenuByRestaurantId/getMenuByRestaurantId_repository.dart';
import 'package:local_basket/domain/repository/restaurants/getNearbyRestaurants/getNearByrestarants_repository.dart';
import 'package:local_basket/domain/repository/restaurants/getRestaurantsByProductName/getRestaurantsByProductName_repository.dart';
import 'package:local_basket/domain/repository/restaurants/guestMenuByRestaurantId/guestMenuByRestaurantId_repository.dart';
import 'package:local_basket/domain/repository/restaurants/guestNearbyRestaurants/guestNearbyRestaurants_repository.dart';
import 'package:local_basket/domain/usecase/address/defaultAddress/get/getDefaultAddress_usecase.dart';
import 'package:local_basket/domain/usecase/address/defaultAddress/post/defaultAddress_usecase.dart';
import 'package:local_basket/domain/usecase/address/deleteAddress/deleteAddress_usecase.dart';
import 'package:local_basket/domain/usecase/address/getAddress/getAddress_usecase.dart';
import 'package:local_basket/domain/usecase/address/saveAddress/saveAddress_usecase.dart';
import 'package:local_basket/domain/usecase/authentication/current_customer_usecase.dart';
import 'package:local_basket/domain/usecase/authentication/deleteAccount_usecase.dart';
import 'package:local_basket/domain/usecase/authentication/rolesPost_usecase.dart';
import 'package:local_basket/domain/usecase/authentication/signin_usecase.dart';
import 'package:local_basket/domain/usecase/authentication/signup_usecase.dart';
import 'package:local_basket/domain/usecase/authentication/trigger_otp_usecase.dart';
import 'package:local_basket/domain/usecase/authentication/update_current_customer_usecase.dart';
import 'package:local_basket/domain/usecase/cart/clearCart/clearCart_usecase.dart';
import 'package:local_basket/domain/usecase/cart/createCart/createCart_usecase.dart';
import 'package:local_basket/domain/usecase/cart/getCart/getCart_usecase.dart';
import 'package:local_basket/domain/usecase/cart/productsAddToCart/productsAddtoCart_usecase.dart';
import 'package:local_basket/domain/usecase/cart/updateCartItems/updateCartItems_usecase.dart';
import 'package:local_basket/domain/usecase/location/location_usecase.dart';
import 'package:local_basket/domain/usecase/offers/restaurant_offers/restaurant_offers_usecase.dart';
import 'package:local_basket/domain/usecase/offers/restaurant_offers/validate_offer_usecase.dart';
import 'package:local_basket/domain/usecase/orders/createOrder/createOrder_usecase.dart';
import 'package:local_basket/domain/usecase/orders/orderHistory/orderHistory_usecase.dart';
import 'package:local_basket/domain/usecase/orders/reOrder/reOrder_usecase.dart';
import 'package:local_basket/domain/usecase/payment/payment_usecase.dart';
import 'package:local_basket/domain/usecase/restaurants/getMenuByRestaurantId/getMenuByRestaurantId_usecase.dart';
import 'package:local_basket/domain/usecase/restaurants/getNearbyRestaurants/getNearByrestarants_usecase.dart';
import 'package:local_basket/domain/usecase/restaurants/getRestaurantsByProductName/getRestaurantsByProductName_usecase.dart';
import 'package:local_basket/domain/usecase/restaurants/guestMenuByRestaurantId/guestMenuByRestaurantId_usecase.dart';
import 'package:local_basket/domain/usecase/restaurants/guestNearbyRestaurants/guestNearbyRestaurants_usecase.dart';
import 'package:local_basket/presentation/cubit/address/defaultAddress/get/getDefaultAddress_cubit.dart';
import 'package:local_basket/presentation/cubit/address/defaultAddress/post/defaultAddress_cubit.dart';
import 'package:local_basket/presentation/cubit/address/deleteAddress/deleteAddress_cubit.dart';
import 'package:local_basket/presentation/cubit/address/getAddress/getAddress_cubit.dart';
import 'package:local_basket/presentation/cubit/address/saveAddress/saveAddress_cubit.dart';
import 'package:local_basket/presentation/cubit/authentication/currentcustomer/get/current_customer_cubit.dart';
import 'package:local_basket/presentation/cubit/authentication/currentcustomer/update/update_current_customer_cubit.dart';
import 'package:local_basket/presentation/cubit/authentication/deleteAccount/deleteAccount_cubit.dart';
import 'package:local_basket/presentation/cubit/authentication/login/trigger_otp_cubit.dart';
import 'package:local_basket/presentation/cubit/authentication/roles/rolesPost_cubit.dart';
import 'package:local_basket/presentation/cubit/authentication/signUp/signup_cubit.dart';
import 'package:local_basket/presentation/cubit/authentication/signin/sigin_cubit.dart';
import 'package:local_basket/presentation/cubit/cart/clearCart/clearCart_cubit.dart';
import 'package:local_basket/presentation/cubit/cart/createCart/createCart_cubit.dart';
import 'package:local_basket/presentation/cubit/cart/getCart/getCart_cubit.dart';
import 'package:local_basket/presentation/cubit/cart/productsAddToCart/productsAddtoCart_cubit.dart';
import 'package:local_basket/presentation/cubit/cart/updateCartItems/updateCartItems_cubit.dart';
import 'package:local_basket/presentation/cubit/location/location_cubit.dart';
import 'package:local_basket/presentation/cubit/offers/restaurant_offers/get_restaurant_offers/restaurant_offers_cubit.dart';
import 'package:local_basket/presentation/cubit/offers/restaurant_offers/validate_offers/validate_offer_cubit.dart';
import 'package:local_basket/presentation/cubit/orders/createOrder/createOrder_cubit.dart';
import 'package:local_basket/presentation/cubit/orders/orderHistory/orderHistory_cubit.dart';
import 'package:local_basket/presentation/cubit/orders/reOrder/reOrder_cubit.dart';
import 'package:local_basket/presentation/cubit/payment/payment_cubit.dart';
import 'package:local_basket/presentation/cubit/restaurants/getMenuByRestaurantId/getMenuByRestaurantId_cubit.dart';
import 'package:local_basket/presentation/cubit/restaurants/getNearbyRestaurants/getNearByrestarants_cubit.dart';
import 'package:local_basket/presentation/cubit/restaurants/getRestaurantsByProductName/getRestaurantsByProductName_cubit.dart';
import 'package:local_basket/presentation/cubit/restaurants/guestMenuByRestaurantId/guestMenuByRestaurantId_cubit.dart';
import 'package:local_basket/presentation/cubit/restaurants/guestNearbyRestaurants/guestNearbyRestaurants_cubit.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;

final GetIt sl = GetIt.instance;

void init() {
  sl.registerLazySingleton<Dio>(() => Dio());
  sl.registerLazySingleton(() => const FlutterSecureStorage());
  sl.registerLazySingleton(() => NetworkService());
  sl.registerLazySingleton<DioClient>(
    () => DioClient(sl<Dio>(), secureStorage: sl<FlutterSecureStorage>()),
  );

  //network
  sl.registerFactory<NetworkCubit>(() => NetworkCubit());

  sl.registerLazySingleton<TriggerOtpRemoteDataSource>(
    () => TriggerOtpRemoteDataSourceImpl(client: sl<DioClient>().dio),
  );
  sl.registerLazySingleton<TriggerOtpRepository>(
    () => TriggerOtpRepositoryImpl(
        remoteDataSource: sl<TriggerOtpRemoteDataSource>()),
  );
  sl.registerLazySingleton(
    () => TriggerOtpValidationUseCase(repository: sl<TriggerOtpRepository>()),
  );
  sl.registerFactory(() => TriggerOtpCubit(
        useCase: sl<TriggerOtpValidationUseCase>(),
        networkService: sl<NetworkService>(),
      ));

//signin

  sl.registerLazySingleton<SignInRemoteDataSource>(
    () => SignInRemoteDataSourceImpl(client: sl<DioClient>().dio),
  );
  sl.registerLazySingleton<SignInRepository>(
    () => SignInRepositoryImpl(remoteDataSource: sl<SignInRemoteDataSource>()),
  );
  sl.registerLazySingleton(
    () => SignInValidationUseCase(repository: sl<SignInRepository>()),
  );
  sl.registerFactory(() => SignInCubit(
        useCase: sl<SignInValidationUseCase>(),
        networkService: sl<NetworkService>(),
        // createCartCubit: sl(),
      ));

  //signup

  sl.registerLazySingleton<SignUpRemoteDataSource>(
    () => SignUpRemoteDataSourceImpl(client: sl<DioClient>().dio),
  );
  sl.registerLazySingleton<SignUpRepository>(
    () => SignUpRepositoryImpl(remoteDataSource: sl<SignUpRemoteDataSource>()),
  );
  sl.registerLazySingleton(
    () => SignUpValidationUseCase(repository: sl<SignUpRepository>()),
  );
  sl.registerFactory(() => SignUpCubit(
        useCase: sl<SignUpValidationUseCase>(),
        networkService: sl<NetworkService>(),
      ));

  //RolePost
  sl.registerLazySingleton<RolePostRemoteDatasource>(
    () => RolePostRemoteDataSourceImpl(client: sl<DioClient>().dio),
  );

  sl.registerLazySingleton<RolePostRepository>(
    () => RolePostRepoImpl(remoteDataSource: sl<RolePostRemoteDatasource>()),
  );
  sl.registerLazySingleton(
    () => RolePostUsecase(sl<RolePostRepository>()),
  );

  sl.registerFactory(
      () => RolePostCubit(sl<RolePostUsecase>(), sl<NetworkService>()));

  //currentcustomer

  sl.registerLazySingleton<CurrentCustomerRemoteDataSource>(
    () => CurrentCustomerRemoteDataSourceImpl(client: sl<DioClient>().dio),
  );
  sl.registerLazySingleton<CurrentCustomerRepository>(
    () => CurrentCustomerRepositoryImpl(
        remoteDataSource: sl<CurrentCustomerRemoteDataSource>()),
  );
  sl.registerLazySingleton(
    () => CurrentCustomerValidationUseCase(sl<CurrentCustomerRepository>()),
  );
  sl.registerFactory(() => CurrentCustomerCubit(
      sl<CurrentCustomerValidationUseCase>(), sl<NetworkService>()));

  //location//

  sl.registerLazySingleton<LocationRemoteDataSource>(
    () => LocationRemoteDataSourceImpl(client: http.Client()),
  );
  sl.registerLazySingleton<LocationRepository>(
    () => LocationRepositoryImpl(
        remoteDataSource: sl<LocationRemoteDataSource>(),
        latLangRemoteDataSource: sl<LocationRemoteDataSource>()),
  );
  sl.registerLazySingleton(
    () => LocationUsecase(
        repository: sl<LocationRepository>(),
        latLongRepository: sl<LocationRepository>()),
  );
  sl.registerFactory(() => LocationCubit(
        usecase: sl<LocationUsecase>(),
        networkService: sl<NetworkService>(),
      ));

  //GetNearByRestaurants

  sl.registerLazySingleton<GetNearByRestaurantsRemoteDataSource>(
    () => GetNearByRestaurantsRemoteDataSourceImpl(client: sl<DioClient>().dio),
  );
  sl.registerLazySingleton<GetNearByRestaurantsRepository>(
    () => GetNearByRestaurantsRepositoryImpl(
        remoteDataSource: sl<GetNearByRestaurantsRemoteDataSource>()),
  );
  sl.registerLazySingleton(
    () => GetNearByRestaurantsUseCase(
        repository: sl<GetNearByRestaurantsRepository>()),
  );
  sl.registerFactory(() => GetNearbyRestaurantsCubit(
        getNearbyRestaurantsUseCase: sl<GetNearByRestaurantsUseCase>(),
      ));

  //GetMenuByRestaurantId
  sl.registerLazySingleton<GetMenuByRestaurantIdRemoteDataSource>(
    () =>
        GetMenuByRestaurantIdRemoteDataSourceImpl(client: sl<DioClient>().dio),
  );
  sl.registerLazySingleton<GetMenuByRestaurantIdRepository>(
    () => GetMenuByRestaurantIdRepositoryImpl(
        remoteDataSource: sl<GetMenuByRestaurantIdRemoteDataSource>()),
  );
  sl.registerLazySingleton(
    () => GetMenuByRestaurantIdUseCase(
        repository: sl<GetMenuByRestaurantIdRepository>()),
  );
  sl.registerFactory(() => GetMenuByRestaurantIdCubit(
        sl<GetMenuByRestaurantIdUseCase>(),
      ));

  //CreateCart
  sl.registerLazySingleton<CreateCartRemoteDataSource>(
    () => CreateCartRemoteDataSourceImpl(client: sl<DioClient>().dio),
  );
  sl.registerLazySingleton<CreateCartRepository>(
    () => CreateCartRepositoryImpl(
        remoteDataSource: sl<CreateCartRemoteDataSource>()),
  );
  sl.registerLazySingleton(
    () => CreateCartUseCase(repository: sl<CreateCartRepository>()),
  );
  sl.registerFactory(() => CreateCartCubit(
        sl<CreateCartUseCase>(),
        sl<NetworkService>(),
      ));

  //GetCart
  sl.registerLazySingleton<GetCartRemoteDataSource>(
    () => GetCartRemoteDataSourceImpl(client: sl<DioClient>().dio),
  );
  sl.registerLazySingleton<GetCartRepository>(
    () =>
        GetCartRepositoryImpl(remoteDataSource: sl<GetCartRemoteDataSource>()),
  );
  sl.registerLazySingleton(
    () => GetCartUseCase(repository: sl<GetCartRepository>()),
  );
  sl.registerFactory(() => GetCartCubit(
        sl<GetCartUseCase>(),
        sl<NetworkService>(),
      ));

  //ProductsAddToCart
  sl.registerLazySingleton<ProductsAddToCartRemoteDataSource>(
    () => ProductsAddToCartRemoteDataSourceImpl(client: sl<DioClient>().dio),
  );
  sl.registerLazySingleton<ProductsAddToCartRepository>(
    () => ProductsAddToCartRepositoryImpl(
        remoteDataSource: sl<ProductsAddToCartRemoteDataSource>()),
  );
  sl.registerLazySingleton(
    () => ProductsAddToCartUseCase(sl<ProductsAddToCartRepository>()),
  );
  sl.registerFactory(() => ProductsAddToCartCubit(
        sl<ProductsAddToCartUseCase>(),
        sl<NetworkService>(),
      ));

  //UpdateCartItems
  sl.registerLazySingleton<UpdateCartItemsRemoteDataSource>(
    () => UpdateCartItemsRemoteDataSourceImpl(client: sl<DioClient>().dio),
  );
  sl.registerLazySingleton<UpdateCartItemsRepository>(
    () => UpdateCartItemsRepositoryImpl(
        remoteDataSource: sl<UpdateCartItemsRemoteDataSource>()),
  );
  sl.registerLazySingleton(
    () => UpdateCartItemsUseCase(repository: sl<UpdateCartItemsRepository>()),
  );
  sl.registerFactory(() => UpdateCartItemsCubit(
        sl<UpdateCartItemsUseCase>(),
        sl<NetworkService>(),
      ));

  //SaveAddress
  sl.registerLazySingleton<SaveAddressRemoteDataSource>(
    () => SaveAddressRemoteDataSourceImpl(client: sl<DioClient>().dio),
  );
  sl.registerLazySingleton<SaveAddressRepository>(
    () => SaveAddressRepositoryImpl(
        remoteDataSource: sl<SaveAddressRemoteDataSource>()),
  );
  sl.registerLazySingleton(
    () => SaveAddressUseCase(repository: sl<SaveAddressRepository>()),
  );
  sl.registerFactory(() => SaveAddressCubit(
        sl<SaveAddressUseCase>(),
        sl<NetworkService>(),
      ));

  //GetAddress
  sl.registerLazySingleton<GetAddressRemoteDataSource>(
    () => GetAddressRemoteDataSourceImpl(client: sl<DioClient>().dio),
  );
  sl.registerLazySingleton<GetAddressRepository>(
    () => GetAddressRepositoryImpl(
        remoteDataSource: sl<GetAddressRemoteDataSource>()),
  );
  sl.registerLazySingleton(
    () => GetAddressUseCase(repository: sl<GetAddressRepository>()),
  );
  sl.registerFactory(() => GetAddressCubit(
        sl<GetAddressUseCase>(),
        sl<NetworkService>(),
      ));

  //Payment
  sl.registerLazySingleton<PaymentRemoteDataSource>(
    () => PaymentRemoteDataSourceImpl(client: sl<DioClient>().dio),
  );
  sl.registerLazySingleton<PaymentRepository>(
    () =>
        PaymentRepositoryImpl(remoteDataSource: sl<PaymentRemoteDataSource>()),
  );
  sl.registerLazySingleton(
    () => PaymentUseCase(repository: sl<PaymentRepository>()),
  );
  sl.registerFactory(() => PaymentCubit(
        sl<PaymentUseCase>(),
        sl<NetworkService>(),
      ));

  //GetRestaurantsByProductName
  sl.registerLazySingleton<GetRestaurantsByProductNameRemoteDataSource>(
    () => GetRestaurantsByProductNameRemoteDataSourceImpl(
        client: sl<DioClient>().dio),
  );
  sl.registerLazySingleton<GetRestaurantsByProductNameRepository>(
    () => GetRestaurantsByProductNameRepositoryImpl(
        remoteDataSource: sl<GetRestaurantsByProductNameRemoteDataSource>()),
  );
  sl.registerLazySingleton(
    () => GetRestaurantsByProductNameUseCase(
        repository: sl<GetRestaurantsByProductNameRepository>()),
  );
  sl.registerFactory(() => GetRestaurantsByProductNameCubit(
        sl<GetRestaurantsByProductNameUseCase>(),
      ));

  //CreateOrder
  sl.registerLazySingleton<CreateOrderRemoteDataSource>(
    () => CreateOrderRemoteDataSourceImpl(client: sl<DioClient>().dio),
  );
  sl.registerLazySingleton<CreateOrderRepository>(
    () => CreateOrderRepositoryImpl(
        remoteDataSource: sl<CreateOrderRemoteDataSource>()),
  );
  sl.registerLazySingleton(
    () => CreateOrderUseCase(repository: sl<CreateOrderRepository>()),
  );
  sl.registerFactory(() => CreateOrderCubit(
        sl<CreateOrderUseCase>(),
        sl<NetworkService>(),
      ));

  //OrderHistory
  sl.registerLazySingleton<OrderHistoryRemoteDataSource>(
    () => OrderHistoryRemoteDataSourceImpl(client: sl<DioClient>().dio),
  );
  sl.registerLazySingleton<OrderHistoryRepository>(
    () => OrderHistoryRepositoryImpl(
        remoteDataSource: sl<OrderHistoryRemoteDataSource>()),
  );
  sl.registerLazySingleton(
    () => OrderHistoryUseCase(repository: sl<OrderHistoryRepository>()),
  );
  sl.registerFactory(() => OrderHistoryCubit(
        sl<OrderHistoryUseCase>(),
        sl<NetworkService>(),
      ));

  //ClearCart
  sl.registerLazySingleton<ClearCartRemoteDataSource>(
    () => ClearCartRemoteDataSourceImpl(client: sl<DioClient>().dio),
  );
  sl.registerLazySingleton<ClearCartRepository>(
    () => ClearCartRepositoryImpl(
        remoteDataSource: sl<ClearCartRemoteDataSource>()),
  );
  sl.registerLazySingleton(
    () => ClearCartUseCase(repository: sl<ClearCartRepository>()),
  );
  sl.registerFactory(() => ClearCartCubit(
        sl<ClearCartUseCase>(),
        sl<NetworkService>(),
      ));

  //ReOrder
  sl.registerLazySingleton<ReOrderRemoteDataSource>(
    () => ReOrderRemoteDataSourceImpl(client: sl<DioClient>().dio),
  );
  sl.registerLazySingleton<ReOrderRepository>(
    () =>
        ReOrderRepositoryImpl(remoteDataSource: sl<ReOrderRemoteDataSource>()),
  );
  sl.registerLazySingleton(
    () => ReOrderUseCase(repository: sl<ReOrderRepository>()),
  );
  sl.registerFactory(() => ReOrderCubit(
        sl<ReOrderUseCase>(),
        sl<NetworkService>(),
      ));

  //DeleteAddress
  sl.registerLazySingleton<DeleteAddressRemoteDataSource>(
    () => DeleteAddressRemoteDataSourceImpl(client: sl<DioClient>().dio),
  );
  sl.registerLazySingleton<DeleteAddressRepository>(
    () => DeleteAddressRepositoryImpl(
        remoteDataSource: sl<DeleteAddressRemoteDataSource>()),
  );
  sl.registerLazySingleton(
    () => DeleteAddressUseCase(repository: sl<DeleteAddressRepository>()),
  );
  sl.registerFactory(() => DeleteAddressCubit(
        sl<DeleteAddressUseCase>(),
        sl<NetworkService>(),
      ));

  //UpdateCurrentCustomer

  sl.registerLazySingleton<UpdateCurrentCustomerRemoteDatasource>(
    () =>
        UpdateCurrentCustomerRemoteDataSourceImpl(client: sl<DioClient>().dio),
  );
  sl.registerLazySingleton<UpdateCurrentCustomerRepository>(
    () => UpdateCurrentCustomerRepositoryImpl(
        remoteDatasource: sl<UpdateCurrentCustomerRemoteDatasource>()),
  );
  sl.registerLazySingleton(
    () => UpdateCurrentCustomerUseCase(
        repository: sl<UpdateCurrentCustomerRepository>()),
  );
  sl.registerFactory(() => UpdateCurrentCustomerCubit(
        useCase: sl<UpdateCurrentCustomerUseCase>(),
        networkService: sl<NetworkService>(),
      ));

  //DefaultAddress

  sl.registerLazySingleton<DefaultAddressRemoteDataSource>(
    () => DefaultAddressRemoteDataSourceImpl(client: sl<DioClient>().dio),
  );
  sl.registerLazySingleton<DefaultAddressRepository>(
    () => DefaultAddressRepositoryImpl(
        remoteDataSource: sl<DefaultAddressRemoteDataSource>()),
  );
  sl.registerLazySingleton(
    () => DefaultAddressUseCase(repository: sl<DefaultAddressRepository>()),
  );
  sl.registerFactory(() => DefaultAddressCubit(
        sl<DefaultAddressUseCase>(),
        sl<NetworkService>(),
      ));

  //AddressSavetoCart
  sl.registerLazySingleton<AddressSavetoCartRemoteDataSource>(
    () => AddressSavetoCartRemoteDataSourceImpl(client: sl<DioClient>().dio),
  );
  sl.registerLazySingleton<AddressSavetoCartRepository>(
    () => AddressSavetoCartRepositoryImpl(
        remoteDataSource: sl<AddressSavetoCartRemoteDataSource>()),
  );
  sl.registerLazySingleton(
    () =>
        AddressSavetoCartUseCase(repository: sl<AddressSavetoCartRepository>()),
  );
  sl.registerFactory(() => AddressSavetoCartCubit(
        sl<AddressSavetoCartUseCase>(),
        sl<NetworkService>(),
      ));

  //GuestNearbyRestaurants
  sl.registerLazySingleton<GuestNearByRestaurantsRemoteDataSource>(
    () =>
        GuestNearByRestaurantsRemoteDataSourceImpl(client: sl<DioClient>().dio),
  );
  sl.registerLazySingleton<GuestNearByRestaurantsRepository>(
    () => GuestNearByRestaurantsRepositoryImpl(
        remoteDataSource: sl<GuestNearByRestaurantsRemoteDataSource>()),
  );
  sl.registerLazySingleton(
    () => GuestNearByRestaurantsUseCase(
        repository: sl<GuestNearByRestaurantsRepository>()),
  );
  sl.registerFactory(() => GuestNearByRestaurantsCubit(
        sl<GuestNearByRestaurantsUseCase>(),
      ));

  //GuestMenuByRestaurantId
  sl.registerLazySingleton<GuestMenuByRestaurantIdRemoteDataSource>(
    () => GuestMenuByRestaurantIdRemoteDataSourceImpl(
        client: sl<DioClient>().dio),
  );
  sl.registerLazySingleton<GuestMenuByRestaurantIdRepository>(
    () => GuestMenuByRestaurantIdRepositoryImpl(
        remoteDataSource: sl<GuestMenuByRestaurantIdRemoteDataSource>()),
  );
  sl.registerLazySingleton(
    () => GuestMenuByRestaurantIdUseCase(
        repository: sl<GuestMenuByRestaurantIdRepository>()),
  );
  sl.registerFactory(() => GuestMenuByRestaurantIdCubit(
        sl<GuestMenuByRestaurantIdUseCase>(),
      ));

  //DeleteAccount
  sl.registerLazySingleton<DeleteAccountRemoteDataSource>(
    () => DeleteAccountRemoteDataSourceImpl(client: sl<DioClient>().dio),
  );
  sl.registerLazySingleton<DeleteAccountRepository>(
    () => DeleteAccountRepositoryImpl(
        remoteDataSource: sl<DeleteAccountRemoteDataSource>()),
  );
  sl.registerLazySingleton(
    () => DeleteAccountUseCase(repository: sl<DeleteAccountRepository>()),
  );
  sl.registerFactory(() => DeleteAccountCubit(
        sl<DeleteAccountUseCase>(),
      ));

  //RestaurantOffers

  sl.registerLazySingleton<RestaurantOffersRemoteDataSource>(
    () => RestaurantOffersRemoteDataSourceImpl(client: sl<DioClient>().dio),
  );
  sl.registerLazySingleton<RestaurantOffersRepository>(
    () => RestaurantOffersRepositoryImpl(
        remoteDataSource: sl<RestaurantOffersRemoteDataSource>()),
  );
  sl.registerLazySingleton(
    () => RestaurantOffersUseCase(repository: sl<RestaurantOffersRepository>()),
  );
  sl.registerFactory(() => RestaurantOffersCubit(
        sl<RestaurantOffersUseCase>(),
      ));

      //ValidateOffer
        sl.registerLazySingleton<ValidateOfferRemoteDataSource>(
    () => ValidateOfferRemoteDataSourceImpl(client: sl<DioClient>().dio),
  );
  sl.registerLazySingleton<ValidateOfferRepository>(
    () => ValidateOfferRepositoryImpl(
        remoteDataSource: sl<ValidateOfferRemoteDataSource>()),
  );
  sl.registerLazySingleton(
    () => ValidateOfferUseCase(repository: sl<ValidateOfferRepository>()),
  );
  sl.registerFactory(() => ValidateOfferCubit(
        sl<ValidateOfferUseCase>(),
      ));
}
