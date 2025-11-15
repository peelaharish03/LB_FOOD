// import 'package:local_basket/core/constants/colors.dart';
// import 'package:local_basket/core/constants/rating_service.dart';
// import 'package:local_basket/data/model/orders/orderHistory/orderHistory_model.dart';
// import 'package:local_basket/presentation/cubit/cart/clearCart/clearCart_cubit.dart';
// import 'package:local_basket/presentation/cubit/cart/getCart/getCart_cubit.dart';
// import 'package:local_basket/presentation/cubit/cart/getCart/getCart_state.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:intl/intl.dart';

// Future<bool?> ShowReplaceCartDialog({
//   required BuildContext context,
//   required Content order,
// }) async {
//   return showDialog<bool>(
//     context: context,
//     barrierDismissible: false,
//     builder: (context) => AlertDialog(
//       title: const Text('Replace cart items?'),
//       content: const Text(
//         'Your cart contains dishes from a previous restaurant. '
//         'Do you want to discard the selection and add dishes from this restaurant?',
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.pop(context, false),
//           child: const Text('No'),
//         ),
//         TextButton(
//           onPressed: () async {
//             await context.read<ClearCartCubit>().clearCart(context);

//             Navigator.pop(context, true);
//           },
//           child: const Text('Yes'),
//         ),
//       ],
//     ),
//   );
// }

// Widget BuildOrderItem({
//   required Content order,
//   required BuildContext context,
//   required Map<String, bool> itemInCartStatus,
//   required Map<String, int> itemQuantities,
//   required Function(void Function()) setState,
//   required Function(OrderItem, int) updateItemInCart,
//   required Function(OrderItem) removeItemFromCart,
//   required int? bussinessId,
//   required Function(OrderItem, int, String) addNewItemToCart,
// }) {
//   return Container(
//     margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
//     decoration: BoxDecoration(
//       borderRadius: BorderRadius.circular(12),
//       color: Colors.white,
//       boxShadow: [
//         BoxShadow(
//           color: Colors.black12,
//           blurRadius: 6,
//           offset: const Offset(0, 2),
//         ),
//       ],
//     ),
//     child: Column(
//       children: [
//         Container(
//           padding: const EdgeInsets.all(12),
//           decoration: BoxDecoration(
//             color: AppColor.PrimaryColor.withOpacity(0.2),
//             borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
//           ),
//           child: Row(
//             children: [
//               SizedBox(
//                 width: 50,
//                 height: 50,
//                 child: order.orderItems.isEmpty
//                     ? Icon(Icons.restaurant, color: Colors.grey[400], size: 24)
//                     : null,
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(order.businessName ?? 'Restaurant',
//                         style: const TextStyle(
//                             fontSize: 16, fontWeight: FontWeight.w600)),
//                     const SizedBox(height: 4),
//                     Text(
//                       DateFormat('EEE, MMM d • h:mm a')
//                           .format(order.createdDate ?? DateTime.now()),
//                       style: TextStyle(fontSize: 12, color: Colors.grey[600]),
//                     ),
//                   ],
//                 ),
//               ),
//               Container(
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//                 decoration: BoxDecoration(
//                   color:
//                       GetStatusColor(order.orderStatus ?? '').withOpacity(0.15),
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 child: Text(
//                   order.orderStatus ?? 'Status',
//                   style: TextStyle(
//                     color: GetStatusColor(order.orderStatus ?? ''),
//                     fontSize: 12,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//         Padding(
//           padding: const EdgeInsets.all(12),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text('Your order:',
//                   style: TextStyle(
//                       fontSize: 13,
//                       fontWeight: FontWeight.w500,
//                       color: Colors.grey[700])),
//               const SizedBox(height: 8),
//               ...order.orderItems.map((item) {
//                 final itemKey = '${item.productId}_${item.productName}';
//                 final isInCart = itemInCartStatus[itemKey] ?? false;
//                 final quantity = itemQuantities[itemKey] ?? 1;

//                 return Padding(
//                   padding: const EdgeInsets.only(bottom: 6),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         children: [
//                           Container(
//                             width: 6,
//                             height: 6,
//                             margin: const EdgeInsets.only(right: 8),
//                             decoration: BoxDecoration(
//                               color: AppColor.PrimaryColor,
//                               shape: BoxShape.circle,
//                             ),
//                           ),
//                           Expanded(
//                             child: Text(
//                               '${item.productName} (${item.quantity} items)',
//                               style: const TextStyle(fontSize: 14),
//                             ),
//                           ),
//                           if (isInCart) ...[
//                             GestureDetector(
//                               onTap: () {
//                                 setState(() {
//                                   if (quantity > 0) {
//                                     itemQuantities[itemKey] = quantity - 1;
//                                     updateItemInCart(item, quantity - 1);
//                                   } else {
//                                     itemInCartStatus.remove(itemKey);
//                                     itemQuantities.remove(itemKey);
//                                     removeItemFromCart(item);
//                                   }
//                                 });
//                               },
//                               child: Container(
//                                 padding: const EdgeInsets.all(6),
//                                 decoration: BoxDecoration(
//                                   color: AppColor.PrimaryColor,
//                                   shape: BoxShape.circle,
//                                 ),
//                                 child: const Icon(
//                                   Icons.remove,
//                                   size: 12,
//                                   color: Colors.white,
//                                 ),
//                               ),
//                             ),
//                             Padding(
//                               padding:
//                                   const EdgeInsets.symmetric(horizontal: 8),
//                               child: Text(
//                                 '$quantity',
//                                 style: const TextStyle(fontSize: 14),
//                               ),
//                             ),
//                           ],
//                           GestureDetector(
//                             onTap: () async {
//                               final state = context.read<GetCartCubit>().state;
//                               if (state is GetCartLoaded) {
//                                 final cartItems = state.cart.cartItems;
//                                 final currentBusinessId = state.cart.businessId;

//                                 if (cartItems.isNotEmpty &&
//                                     currentBusinessId != order.businessId) {
//                                   final shouldReplace =
//                                       await ShowReplaceCartDialog(
//                                     context: context,
//                                     order: order,
//                                   );
//                                   if (shouldReplace != true) {
//                                     return;
//                                   }
//                                   setState(() {
//                                     itemInCartStatus.clear();
//                                     itemQuantities.clear();
//                                   });
//                                 }

//                                 final newQuantity =
//                                     (isInCart ? quantity : 1) + 1;

//                                 setState(() {
//                                   itemInCartStatus[itemKey] = true;
//                                   itemQuantities[itemKey] = newQuantity;
//                                 });

//                                 addNewItemToCart(item, newQuantity, itemKey);
//                               } else {
//                                 print('else');
//                               }
//                             },
//                             child: Container(
//                               padding: const EdgeInsets.all(6),
//                               decoration: BoxDecoration(
//                                 color: AppColor.PrimaryColor,
//                                 shape: BoxShape.circle,
//                               ),
//                               child: Icon(
//                                 isInCart ? Icons.add : Icons.add_shopping_cart,
//                                 size: 12,
//                                 color: Colors.white,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                       Text(
//                         '₹${item.price?.toStringAsFixed(2)}',
//                         style: const TextStyle(
//                           fontSize: 14,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ],
//                   ),
//                 );
//               }),
//               const SizedBox(height: 12),

//               // Rate & Review button for delivered orders if not rated yet
//               if ((order.orderStatus ?? '').toUpperCase() == 'DELIVERED')
//                 FutureBuilder<bool>(
//                   future: RatingService().hasRated(order.orderNumber ?? ''),
//                   builder: (context, snapshot) {
//                     final hasRated = snapshot.data ?? false;
//                     if (hasRated) return const SizedBox.shrink();
//                     return Align(
//                       alignment: Alignment.centerRight,
//                       child: ElevatedButton.icon(
//                         onPressed: () {
//                           RatingService()
//                               .showRatingDialog(context: context, order: order);
//                         },
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: AppColor.PrimaryColor,
//                           padding: const EdgeInsets.symmetric(
//                               horizontal: 12, vertical: 8),
//                           shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(8)),
//                         ),
//                         icon:
//                             const Icon(Icons.rate_review, color: Colors.white),
//                         label: const Text(
//                           'Rate & Review',
//                           style: TextStyle(color: Colors.white),
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//             ],
//           ),
//         ),
//       ],
//     ),
//   );
// }

// Color GetStatusColor(String status) {
//   switch (status.toLowerCase()) {
//     case 'delivered':
//       return Colors.green;
//     case 'cancelled':
//       return Colors.red;
//     case 'placed':
//       return Colors.orange;
//     case 'preparing':
//       return Colors.blue;
//     default:
//       return Colors.orange;
//   }
// }
