import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:local_basket/core/constants/global_rating_listener.dart';
import 'package:local_basket/core/network/network_cubit.dart';
import 'package:local_basket/firebase_options.dart';
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
import 'package:local_basket/presentation/screen/authentication/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/injection.dart' as di;

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Firebase initialized successfully");
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    print("Firebase initialization error: $e");
  }

  di.init();

  final connectivityResult = await Connectivity().checkConnectivity();
  if (connectivityResult == ConnectivityResult.none) {
    print("No Internet Connection");
  } else {
    print("Connected to the Internet");
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.sl<TriggerOtpCubit>()),
        BlocProvider(create: (_) => di.sl<SignInCubit>()),
        BlocProvider(create: (_) => di.sl<SignUpCubit>()),
        BlocProvider(create: (_) => di.sl<CurrentCustomerCubit>()),
        BlocProvider(create: (_) => di.sl<NetworkCubit>()),
        BlocProvider(create: (_) => di.sl<LocationCubit>()),
        BlocProvider(create: (_) => di.sl<RolePostCubit>()),
        BlocProvider(create: (_) => di.sl<GetNearbyRestaurantsCubit>()),
        BlocProvider(create: (_) => di.sl<GetMenuByRestaurantIdCubit>()),
        BlocProvider(create: (_) => di.sl<CreateCartCubit>()),
        BlocProvider(create: (_) => di.sl<GetCartCubit>()),
        BlocProvider(create: (_) => di.sl<ProductsAddToCartCubit>()),
        BlocProvider(create: (_) => di.sl<UpdateCartItemsCubit>()),
        BlocProvider(create: (_) => di.sl<SaveAddressCubit>()),
        BlocProvider(create: (_) => di.sl<GetAddressCubit>()),
        BlocProvider(create: (_) => di.sl<PaymentCubit>()),
        BlocProvider(create: (_) => di.sl<GetRestaurantsByProductNameCubit>()),
        BlocProvider(create: (_) => di.sl<CreateOrderCubit>()),
        BlocProvider(create: (_) => di.sl<OrderHistoryCubit>()),
        BlocProvider(create: (_) => di.sl<ClearCartCubit>()),
        BlocProvider(create: (_) => di.sl<ReOrderCubit>()),
        BlocProvider(create: (_) => di.sl<DeleteAddressCubit>()),
        BlocProvider(create: (_) => di.sl<UpdateCurrentCustomerCubit>()),
        BlocProvider(create: (_) => di.sl<DefaultAddressCubit>()),
        BlocProvider(create: (_) => di.sl<AddressSavetoCartCubit>()),
        BlocProvider(create: (_) => di.sl<GuestNearByRestaurantsCubit>()),
        BlocProvider(create: (_) => di.sl<GuestMenuByRestaurantIdCubit>()),
        BlocProvider(create: (_) => di.sl<DeleteAccountCubit>()),
        BlocProvider(create: (_) => di.sl<RestaurantOffersCubit>()),
        BlocProvider(create: (_) => di.sl<ValidateOfferCubit>()),
      ],
      child: MaterialApp(
        title: 'local_basket',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.green,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
          useMaterial3: true,
        ),
        home: GlobalRatingListener(
          child: SplashScreen(),
        ),
      ),

    );
  }
}
