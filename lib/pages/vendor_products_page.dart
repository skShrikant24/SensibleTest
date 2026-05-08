import 'dart:convert';

import 'package:GraBiTT/app_State/cart.dart';
import 'package:GraBiTT/app_State/locale_provider.dart';
import 'package:GraBiTT/l10n/app_localizations.dart';
import 'package:GraBiTT/models/product.dart';
import 'package:GraBiTT/models/vendor_product.dart';
import 'package:GraBiTT/pages/product_details_page.dart';
import 'package:GraBiTT/utils/constants.dart';
import 'package:GraBiTT/utils/shared_classes.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class VendorProductsPage extends StatefulWidget {
  final String vendorId;
  final String vendorName;
  final String catergoryId;

  const VendorProductsPage({
    super.key,
    required this.vendorId,
    required this.vendorName,
    required this.catergoryId,
  });

  @override
  State<VendorProductsPage> createState() => _VendorProductsPageState();
}

class _VendorProductsPageState extends State<VendorProductsPage> {
  final TextEditingController _searchController = TextEditingController();

  List<VendorProduct> _allVendorsProduct = [];
  List<VendorProduct> _filteredVendorsProduct = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadVendorsProducts();
  }

  Future<List<VendorProduct>> fetchVendorProducts(
      String vendorId, String catergoryId,
      [String lang = 'en']) async {
    try {
      final url =
          "https://grabitt.in/webservice.asmx/GetProductsByVendor?vendorid=$vendorId&categoryid=$catergoryId&lang=${Uri.encodeComponent(lang)}";
      print("+++++++++++++++++++++");
      print(url);
      print("__________________________");
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) return [];
      final cleaned = response.body.replaceAll(RegExp(r'<[^>]*>'), '').trim();
      if (cleaned.isEmpty ||
          cleaned.toLowerCase() == "no data" ||
          cleaned.toLowerCase() == "fail") {
        return [];
      }
      final decoded = json.decode(cleaned);
      print("+++++++++decoded++++++++++++");
      print(decoded);
      print("__________________________");
      if (decoded is List) {
        return decoded
            .map<VendorProduct>(
                (e) => VendorProduct.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> _loadVendorsProducts() async {
    try {
      final lang = LocaleProvider.instance.languageCode;
      final vendors =
          await fetchVendorProducts(widget.vendorId, widget.catergoryId, lang);
      _allVendorsProduct = vendors;
      _filteredVendorsProduct = vendors;
    } catch (_) {
      _allVendorsProduct = [];
      _filteredVendorsProduct = [];
    }
    setState(() => _loading = false);
  }

  void _onSearchChanged(String query) {
    query = query.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredVendorsProduct = _allVendorsProduct;
      } else {
        _filteredVendorsProduct = _allVendorsProduct
            .where((v) => v.name.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Container(
        decoration: BoxDecoration(
          color: StoreProfileTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: StoreProfileTheme.border.withValues(alpha: .4)),
          boxShadow: [
            BoxShadow(
              color: StoreProfileTheme.border.withValues(alpha: .15),
              blurRadius: 6,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.searchProducts,
            prefixIcon: Icon(Icons.search, color: StoreProfileTheme.accentPink),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged("");
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StoreProfileTheme.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: StoreProfileTheme.background,
        centerTitle: true,
        title: Text(
          widget.vendorName,
          style: GoogleFonts.poppins(
            color: StoreProfileTheme.accentPink,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.pinkAccent),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: _loading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: StoreProfileTheme.accentPink,
                      ),
                    )
                  : _filteredVendorsProduct.isEmpty
                      ? _StateMessage(
                          icon: Icons.search_off,
                          message: "No Matching Product",
                        )
                      : ListenableBuilder(
                          listenable: CartService.instance,
                          builder: (context, _) {
                            return GridView.builder(
                              padding: const EdgeInsets.all(12),
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              itemCount: _filteredVendorsProduct.length,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: .72,
                              ),
                              itemBuilder: (context, index) {
                                final p = _filteredVendorsProduct[index];
                                return _ProductCard(
                                  vendorProduct: p,
                                  onTap: () {
                                    final product = Product.fromVendor(p);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ProductDetailsPage(
                                            product: product),
                                      ),
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
            )
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final VendorProduct vendorProduct;
  final VoidCallback onTap;

  const _ProductCard({
    required this.vendorProduct,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final product = Product.fromVendor(vendorProduct);
    final cart = CartService.instance;
    CartItem? cartItem;
    for (final item in cart.items) {
      if (item.product.id == product.id) {
        cartItem = item;
        break;
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Expanded(
            //   child: (vendorProduct.images.isNotEmpty &&
            //       vendorProduct.images.first.isNotEmpty)
            //       ? Image.network(
            //     vendorProduct.images.first,
            //     fit: BoxFit.cover,
            //     width: double.infinity,
            //     errorBuilder: (_, __, ___) => _placeholder(),
            //   )
            //       : _placeholder(),
            // ),
            Expanded(
              child: (vendorProduct.images.isNotEmpty &&
                      vendorProduct.images.first.isNotEmpty)
                  ? CachedNetworkImage(
                      imageUrl: vendorProduct.images.first,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      fadeInDuration: const Duration(milliseconds: 150),
                      memCacheWidth: 400,
                      maxWidthDiskCache: 500,
                      placeholder: (context, url) {
                        return Container(
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
                      errorWidget: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vendorProduct.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(fontSize: 13),
                  ),
                  Text(
                    "${AppConstants.currencySymbol}${vendorProduct.discountPrice}",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: StoreProfileTheme.accentPink,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: vendorProduct.isActive == 1
                  ? (cartItem == null
                      ? _AddButton(
                          onPressed: () {
                            cart.addItem(product);
                            ToastMessage.success(
                              context: context,
                              msg: "Added to cart",
                            );
                          },
                        )
                      : _QtyControls(
                          cartItem: cartItem,
                          onIncrease: () {
                            cart.increase(cartItem!);
                          },
                          onDecrease: () => cart.decrease(cartItem!),
                        ))
                  : _outOfStock(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: StoreProfileTheme.lightPink.withValues(alpha: .25),
      child: Center(
        child: Icon(
          Icons.image_not_supported,
          size: 48,
          color: StoreProfileTheme.accentPink,
        ),
      ),
    );
  }

  Widget _outOfStock() {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        "Out of Stock",
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.red,
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _AddButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: StoreProfileTheme.accentPink,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add, color: Colors.white, size: 20),
              const SizedBox(width: 6),
              Text(
                AppLocalizations.of(context)!.addToCart,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QtyControls extends StatelessWidget {
  final CartItem cartItem;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  const _QtyControls({
    required this.cartItem,
    required this.onIncrease,
    required this.onDecrease,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: onDecrease,
          icon: Icon(Icons.remove_circle_outline,
              color: StoreProfileTheme.accentPink, size: 24),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            "${cartItem.quantity}",
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: StoreProfileTheme.accentPink,
            ),
          ),
        ),
        IconButton(
          onPressed: onIncrease,
          icon: Icon(Icons.add_circle_outline,
              color: StoreProfileTheme.accentPink, size: 24),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
      ],
    );
  }
}

class _StateMessage extends StatelessWidget {
  final IconData icon;
  final String message;

  const _StateMessage({
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 70, color: StoreProfileTheme.border),
          const SizedBox(height: 14),
          Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
