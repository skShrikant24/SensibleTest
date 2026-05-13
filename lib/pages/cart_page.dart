import 'package:GraBiTT/l10n/app_localizations.dart';
import 'package:GraBiTT/pages/checkout_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app_State/cart.dart';
import '../utils/constants.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final cart = CartService.instance;

  @override
  void initState() {
    super.initState();
       cart.loadFromStorage();
    WidgetsBinding.instance.addPostFrameCallback((_)  {
      cart.syncCartFromServer();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: cart,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: StoreProfileTheme.background,
          appBar: AppBar(
            title: Text(
              AppLocalizations.of(context)!.myCart,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.black,
                fontSize: 18,
              ),
            ),
            backgroundColor: StoreProfileTheme.background,
            foregroundColor: Colors.black,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: (cart.isSyncingCart && cart.items.isEmpty)
              ? const Center(child: CircularProgressIndicator())
              : cart.items.isEmpty
                  ? _emptyCart()
                  : Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: cart.items.length,
                            itemBuilder: (context, index) {
                              final item = cart.items[index];
                              return _cartItem(item);
                            },
                          ),
                        ),
                        _checkoutBar(),
                      ],
                    ),
        );
      },
    );
  }

  Widget _cartItem(CartItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: StoreProfileTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: StoreProfileTheme.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: StoreProfileTheme.border.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: (item.product.allImages.isNotEmpty &&
                    item.product.allImages.first.isNotEmpty)
                ? CachedNetworkImage(
                    imageUrl: item.product.allImages.first,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    fadeInDuration: const Duration(milliseconds: 150),
                    memCacheWidth: 300,
                    maxWidthDiskCache: 400,
                    placeholder: (context, url) {
                      return Container(
                        width: 70,
                        height: 70,
                        color: Colors.grey[200],
                        child: const Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      );
                    },
                    errorWidget: (context, url, error) {
                      return Container(
                        width: 70,
                        height: 70,
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.broken_image_outlined,
                        ),
                      );
                    },
                  )
                : Container(
                    width: 70,
                    height: 70,
                    color: Colors.grey[200],
                    child: const Icon(
                      Icons.image_not_supported_outlined,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  "${AppConstants.currencySymbol}${item.product.discountPrice}",
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: StoreProfileTheme.accentPink),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Row(
                children: [
                  _qtyButton(Icons.remove, () {
                    // setState(() => cart.decrease(item));
                    cart.decrease(item);
                  }),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      item.quantity.toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  _qtyButton(Icons.add, () {
                    // setState(() => cart.increase(item));
                    cart.increase(item);
                  }),
                ],
              ),
              IconButton(
                icon: Icon(Icons.delete_outline,
                    color: StoreProfileTheme.accentPink),
                onPressed: () {
                  // setState(() => cart.remove(item));
                  cart.remove(item);
                },
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(color: StoreProfileTheme.border),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: StoreProfileTheme.accentPink),
      ),
    );
  }

  Widget _checkoutBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: StoreProfileTheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: StoreProfileTheme.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: StoreProfileTheme.border.withValues(alpha: 0.15),
            blurRadius: 10,
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context)!.subtotal,
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: Colors.grey.shade600)),
              Text(
                "${AppConstants.currencySymbol}${cart.finalTotal.toStringAsFixed(0)}",
                style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: StoreProfileTheme.accentPink),
              ),
              Text(
                "Items: ${AppConstants.currencySymbol}${cart.subtotal.toStringAsFixed(0)}",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: StoreProfileTheme.accentPink,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            onPressed: cart.items.isEmpty
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CheckoutPage(),
                      ),
                    );
                  },
            child: Text(
              AppLocalizations.of(context)!.checkout,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined,
              size: 90, color: StoreProfileTheme.border),
          const SizedBox(height: 12),
          Text(
            "Your cart is empty",
            style: GoogleFonts.poppins(
                fontSize: 16,
                color: StoreProfileTheme.accentPink.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }
}
