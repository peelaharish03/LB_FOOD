import 'package:local_basket/components/custom_topbar.dart';
import 'package:flutter/material.dart';

class PromotionsScreen extends StatefulWidget {
  
  const PromotionsScreen({super.key,});
  @override
  _PromotionsScreenState createState() => _PromotionsScreenState();
}

class _PromotionsScreenState extends State<PromotionsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: CustomAppBar(title: "Offers", showBackButton: false),
      body: Center(child: Text('No Offers Yet..!'),)
    );
  }
}
