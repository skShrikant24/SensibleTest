import 'dart:convert';

import 'package:GraBiTT/models/product.dart';
import 'package:GraBiTT/models/vendor_product.dart';
import 'package:GraBiTT/pages/product_details_page.dart';
import 'package:GraBiTT/utils/constants.dart';
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
    // future = fetchVendorProducts(widget.vendorId);
  }


  Future<List<VendorProduct>> fetchVendorProducts(String vendorId,String catergoryId) async {
    try {
      final url =
          "https://grabitt.in/webservice.asmx/GetProductsByVendor?vendorid=$vendorId&categoryid=$catergoryId";

      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) return [];

      final cleaned = response.body.replaceAll(RegExp(r'<[^>]*>'), '').trim();
      print("VENDOR Prodcuts API RAW => $cleaned");
      if (cleaned.isEmpty ||
          cleaned.toLowerCase() == "no data" ||
          cleaned.toLowerCase() == "fail") {
        return [];
      }

      final decoded = json.decode(cleaned);

      if (decoded is List) {
        return decoded
            .map<VendorProduct>(
                (e) => VendorProduct.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }

      return [];
    } catch (e) {
      print("Vendor product error $e");
      return [];
    }
  }

  Future<void> _loadVendorsProducts() async {
    try {
      final vendors = await fetchVendorProducts(
        widget.vendorId,
        widget.catergoryId
      );

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
        _filteredVendorsProduct = _allVendorsProduct.where((v) {
          return v.name.toLowerCase().contains(query);
        }).toList();
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
          border: Border.all(color: StoreProfileTheme.border.withValues(alpha: .4)),
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
            hintText: "Search products...",
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

              /// EMPTY AFTER SEARCH
                  : _filteredVendorsProduct.isEmpty
                  ? _StateMessage(
                icon: Icons.search_off,
                message: "No Matching Product",
              )

              /// PRODUCT GRID
                  : GridView.builder(
                padding: const EdgeInsets.all(12),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                itemCount: _filteredVendorsProduct.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: .75,
                ),
                itemBuilder: (context, index) {
                  final p = _filteredVendorsProduct[index];

                  return GestureDetector(
                    onTap: () {
                      final product = Product.fromVendor(p);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductDetailsPage(product: product),
                        ),
                      );
                    },
                    child: Card(
                      child: Column(
                        children: [
                          Expanded(
                            child: Image.network(
                              p.images.first,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (_,__,___)=>Container(
                                color: StoreProfileTheme.lightPink.withValues(alpha: .25),
                                child: Center(
                                  child: Icon(Icons.store,
                                      size: 48,
                                      color: StoreProfileTheme.accentPink),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              children: [
                                Text(
                                  p.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  "${AppConstants.currencySymbol}${p.discountPrice}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
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
