import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_basket/components/custom_topbar.dart';
import 'package:local_basket/core/constants/colors.dart';
import 'package:local_basket/data/model/offers/promotions/promotions_model.dart';
import 'package:local_basket/data/model/offers/restaurant_offers/restaurant_offers_model.dart';
import 'package:local_basket/presentation/cubit/offers/promotions/promotions_cubit.dart';
import 'package:local_basket/presentation/cubit/offers/promotions/promotions_state.dart';
import 'package:local_basket/presentation/cubit/offers/restaurant_offers/get_restaurant_offers/restaurant_offers_cubit.dart';
import 'package:local_basket/presentation/cubit/offers/restaurant_offers/get_restaurant_offers/restaurant_offers_state.dart';

class OffersScreen extends StatefulWidget {
  const OffersScreen({super.key});

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> {
  List<Object> _combined = const [];

  @override
  void initState() {
    super.initState();
    context.read<PromotionsCubit>().fetchPromotions();
    context.read<RestaurantOffersCubit>().fetchRestaurantOffers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.White,
      appBar: const CustomAppBar(title: "Offers"),
      body: BlocBuilder<RestaurantOffersCubit, RestaurantOffersState>(
        builder: (context, offersState) {
          return BlocBuilder<PromotionsCubit, PromotionsState>(
            builder: (context, promotionsState) {
              final List<PromotionContent> promotions = promotionsState is PromotionsLoaded
                  ? promotionsState.promotions.content
                  : const [];
              final List<Content> offers = offersState is RestaurantOffersLoaded
                  ? offersState.offers.data?.content ?? []
                  : const [];

              _combined = [...promotions, ...offers];

              final bool isLoading =
                  promotionsState is PromotionsLoading ||
                  offersState is RestaurantOffersLoading;

              if (_combined.isEmpty) {
                if (isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                return const _EmptyOffers();
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _combined.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = _combined[index];
                  if (item is PromotionContent) {
                    return _OfferCard(
                      name: item.name ?? item.customerFacingLabel ?? 'Offer',
                      description: item.internalDescription ?? '',
                      couponCode: item.code ?? '',
                    );
                  }
                  final Content offer = item as Content;
                  return _OfferCard(
                    name: offer.name ?? 'Offer',
                    description: offer.description ?? '',
                    couponCode: offer.couponCode ?? '',
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  final String name;
  final String description;
  final String couponCode;

  const _OfferCard({
    required this.name,
    required this.description,
    required this.couponCode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColor.PrimaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.local_offer_outlined,
              color: AppColor.PrimaryColor,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                ],
                if (couponCode.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColor.PrimaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColor.PrimaryColor.withOpacity(0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.confirmation_number_outlined,
                          size: 14,
                          color: AppColor.PrimaryColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          couponCode,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColor.PrimaryColor,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyOffers extends StatelessWidget {
  const _EmptyOffers();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_offer_outlined,
            size: 56,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            "No offers available right now",
            style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.read<PromotionsCubit>().fetchPromotions();
              context.read<RestaurantOffersCubit>().fetchRestaurantOffers();
            },
            child: const Text("Retry"),
          ),
        ],
      ),
    );
  }
}
