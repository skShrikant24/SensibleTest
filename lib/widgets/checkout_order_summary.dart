import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grabitt/app_State/cart.dart';
import 'package:grabitt/l10n/app_localizations.dart';
import 'package:grabitt/utils/constants.dart';
import 'package:grabitt/utils/shared_classes.dart';
import 'checkout_price_row.dart';

class CheckoutOrderSummary extends StatelessWidget {
  const CheckoutOrderSummary({super.key, required this.cart});

  final CartService cart;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.orderSummary,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: StoreProfileTheme.accentPink,
          ),
        ),
        const SizedBox(height: 8),
        ...cart.items.map((item) => _OrderItemCard(item: item)),
        const SizedBox(height: 16),
        _TotalsCard(cart: cart),
      ],
    );
  }
}

class _OrderItemCard extends StatelessWidget {
  const _OrderItemCard({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context) {
    final imageUrl = item.product.allImages.isNotEmpty &&
            item.product.allImages.first.isNotEmpty
        ? item.product.allImages.first
        : null;

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: checkoutCardDecoration(),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    fadeInDuration: const Duration(milliseconds: 150),
                    memCacheWidth: 250,
                    maxWidthDiskCache: 350,
                    placeholder: (_, __) => _imagePlaceholder(),
                    errorWidget: (_, __, ___) => _imageError(),
                  )
                : _imageError(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  'Qty: ${item.quantity}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: StoreProfileTheme.accentPink.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${AppConstants.currencySymbol}${item.total.toStringAsFixed(0)}',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: StoreProfileTheme.accentPink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() => Container(
        width: 60,
        height: 60,
        color: Colors.grey[200],
        child: const Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );

  Widget _imageError() => Container(
        width: 60,
        height: 60,
        color: Colors.grey[200],
        child: const Icon(Icons.broken_image_outlined),
      );
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.cart});

  final CartService cart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: checkoutCardDecoration(),
      child: Column(
        children: [
          CheckoutPriceRow(AppLocalizations.of(context)!.subtotal, cart.subtotal),
          if (cart.gst > 0)
            CheckoutPriceRow('GST (${cart.gstPercent}%)', cart.gst),
          if (cart.deliveryCharge > 0)
            CheckoutPriceRow('Delivery Charge', cart.deliveryCharge),
          if (cart.isNewUserDiscountApplied && cart.newUserDiscountAmount > 0)
            CheckoutPriceRow(
              'New User Discount (${cart.newUserDiscountPercent}% OFF)',
              -cart.newUserDiscountAmount,
              valueColor: Colors.green,
            ),
          if (cart.isEvenOrderDiscountApplied && cart.evenOrderDiscountAmount > 0)
            CheckoutPriceRow(
              'Even Order Discount (${cart.evenOrderDiscountPercent}% OFF)',
              -cart.evenOrderDiscountAmount,
              valueColor: Colors.green,
            ),
          CheckoutPriceRow('Service Fee', cart.serviceFee, showNil: true),
          CheckoutPriceRow(
            cart.handlingFeeText.isNotEmpty ? cart.handlingFeeText : 'Handling Fee',
            cart.handlingFee,
            showNil: true,
          ),
          CheckoutPriceRow('Packaging Fee', cart.packagingFee, showNil: true),
          const Divider(height: 22),
          CheckoutPriceRow('Final Total', cart.finalTotal, isFinal: true),
        ],
      ),
    );
  }
}