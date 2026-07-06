// import 'package:local_basket/components/custom_topbar.dart';
// import 'package:local_basket/core/constants/colors.dart';
// import 'package:local_basket/data/model/orders/orderHistory/orderHistory_model.dart';
// import 'package:local_basket/presentation/cubit/cart/getCart/getCart_cubit.dart';
// import 'package:local_basket/presentation/cubit/cart/getCart/getCart_state.dart';
// import 'package:local_basket/presentation/cubit/cart/productsAddToCart/productsAddtoCart_cubit.dart';
// import 'package:local_basket/presentation/cubit/cart/productsAddToCart/productsAddtoCart_state.dart';
// import 'package:local_basket/presentation/cubit/orders/orderHistory/orderHistory_cubit.dart';
// import 'package:local_basket/presentation/cubit/orders/orderHistory/orderHistory_state.dart';
// import 'package:local_basket/presentation/screen/widgets/order_history/order_history_widget.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';

// class OrderHistoryScreen extends StatefulWidget {
//   const OrderHistoryScreen({super.key});
//   @override
//   _OrderHistoryScreenState createState() => _OrderHistoryScreenState();
// }

// class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
//   final Map<String, bool> _itemInCartStatus = {};
//   final Map<String, int> _itemQuantities = {};
//   int? bussinessId = 0;

//   final int _currentPage = 0;
//   final int _pageSize = 30;
//   final String _searchQuery = '';

//   @override
//   void initState() {
//     super.initState();
//     context
//         .read<OrderHistoryCubit>()
//         .fetchCart(_currentPage, _pageSize, _searchQuery, context);
//     cartId();
//   }

//   void cartId() async {
//     final state = context.read<GetCartCubit>().state;
//     if (state is GetCartLoaded) {
//       bussinessId = state.cart.businessId;
//     } else {
//       bussinessId = 0;
//     }
//     print(bussinessId);
//   }

//   List<Map<String, dynamic>> _createPayload(OrderItem item, int quantity) => [
//         {"productId": item.productId, "quantity": quantity, "price": item.price}
//       ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       appBar: CustomAppBar(
//         title: "Order History",
//         showBackButton: false,
//       ),
//       body: BlocListener<ProductsAddToCartCubit, dynamic>(
//         listener: (context, state) {
//           if (state is ProductsAddToCartFailure ||
//               state is ProductsAddToCartRejected) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(
//                 content: Text(state is ProductsAddToCartFailure
//                     ? 'Failed to add item to cart'
//                     : (state as ProductsAddToCartRejected).message),
//                 backgroundColor: state is ProductsAddToCartFailure
//                     ? Colors.red
//                     : Colors.blue,
//               ),
//             );
//           }
//         },
//         child: BlocBuilder<OrderHistoryCubit, dynamic>(
//           builder: (context, state) {
//             if (state is OrderHistoryLoading) {
//               return Center(
//                   child:
//                       CupertinoActivityIndicator(color: AppColor.PrimaryColor));
//             }
//             if (state is OrderHistoryError) {
//               return const Center(child: Text("Failed to load orders"));
//             }
//             if (state is OrderHistoryLoaded) {
//               if (state.orders.data?.content.isEmpty ?? true) {
//                 return const Center(child: Text("No orders found"));
//               }
//               return _buildOrderList(context, state.orders);
//             }
//             return const Center(child: Text('No orders found'));
//           },
//         ),
//       ),
//     );
//   }

//   Widget _buildOrderList(BuildContext context, OrderHistoryModel model) =>
//       Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//             child: _buildSearchBar(),
//           ),
//           const SizedBox(height: 8),
//           Expanded(
//             child: ListView.separated(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//               itemCount: model.data?.content.length ?? 0,
//               separatorBuilder: (_, __) => const SizedBox(height: 12),
//               itemBuilder: (context, index) {
//                 final order = model.data?.content[index];
//                 if (order == null) return const SizedBox.shrink();
//                 return BuildOrderItem(
//                     order: order,
//                     context: context,
//                     addNewItemToCart: _addNewItemToCart,
//                     itemInCartStatus: _itemInCartStatus,
//                     itemQuantities: _itemQuantities,
//                     removeItemFromCart: _removeItemFromCart,
//                     setState: setState,
//                     bussinessId: bussinessId,
//                     updateItemInCart: _updateItemInCart);
//               },
//             ),
//           ),
//         ],
//       );

//   Widget _buildSearchBar() => Container(
//         decoration: BoxDecoration(
//             color: Colors.white, borderRadius: BorderRadius.circular(8)),
//         child: TextField(
//           decoration: InputDecoration(
//             hintText: 'Search for restaurants and orders',
//             prefixIcon: const Icon(Icons.search, color: Colors.grey),
//             border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
//             contentPadding: const EdgeInsets.symmetric(vertical: 12),
//             filled: true,
//             fillColor: Colors.grey[100],
//           ),
//         ),
//       );

//   Future<void> _addNewItemToCart(
//       OrderItem item, int quantity, String itemKey) async {
//     try {
//       final payload = [
//         {
//           'productId': item.productId,
//           'quantity': quantity,
//           'price': item.price,
//         }
//       ];

//       await context
//           .read<ProductsAddToCartCubit>()
//           .addToCart(payload, context: context);

//       setState(() {
//         _itemInCartStatus[itemKey] = true;
//         _itemQuantities[itemKey] = quantity;
//       });

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Added ${item.productName} to cart'),
//           duration: const Duration(seconds: 1),
//         ),
//       );
//     } catch (e) {
//       if (e is ProductsAddToCartRejected) {
//         setState(() => _itemInCartStatus[itemKey] = false);
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text(e.message), backgroundColor: Colors.blue),
//         );
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Failed to add item to cart'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   void _updateItemInCart(OrderItem item, int newQuantity) async {
//     final itemKey = '${item.productId}_${item.productName}';
//     final previousQuantity = _itemQuantities[itemKey] ?? 1;
//     try {
//       await context
//           .read<ProductsAddToCartCubit>()
//           .addToCart(_createPayload(item, newQuantity), context: context);
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//             content:
//                 Text('Updated ${item.productName} quantity to $newQuantity'),
//             duration: const Duration(seconds: 1)),
//       );
//     } catch (e) {
//       if (e is ProductsAddToCartRejected) {
//         setState(() => _itemQuantities[itemKey] = previousQuantity);
//       }
//     }
//   }

//   void _removeItemFromCart(OrderItem item) {
//     final itemKey = '${item.productId}_${item.productName}';
//     context
//         .read<ProductsAddToCartCubit>()
//         .addToCart(_createPayload(item, 0), context: context)
//         .then((_) {
//       setState(() => _itemInCartStatus[itemKey] = false);
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//             content: Text('Removed ${item.productName} from cart'),
//             duration: const Duration(seconds: 1)),
//       );
//     }).catchError((error) {
//       if (error is ProductsAddToCartRejected) {
//         setState(() => _itemInCartStatus[itemKey] = true);
//       }
//     });
//   }
// }
