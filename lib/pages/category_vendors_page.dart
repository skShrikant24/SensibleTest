import 'package:GraBiTT/Classes/Vender.dart';
import 'package:GraBiTT/pages/store_page.dart';
import 'package:GraBiTT/pages/vendor_products_page.dar.dart';
import 'package:GraBiTT/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CategoryVendorsPage extends StatefulWidget {
  final String categoryName;
  final String categoryId;

  const CategoryVendorsPage({
    super.key,
    required this.categoryName,
    required this.categoryId,
  });

  @override
  State<CategoryVendorsPage> createState() => _CategoryVendorsPageState();
}

class _CategoryVendorsPageState extends State<CategoryVendorsPage> {
  late Future<List<Vendor>> future;
  final TextEditingController _searchController = TextEditingController();

  List<Vendor> _allVendors = [];
  List<Vendor> _filteredVendors = [];
  bool _loading = true;


  @override
  void initState() {
    super.initState();
    _loadVendors();
  }

  Future<void> _loadVendors() async {
    try {
      final vendors = await fetchVendorsByCategory(widget.categoryName);

      _allVendors = vendors;
      _filteredVendors = vendors;
    } catch (_) {
      _allVendors = [];
      _filteredVendors = [];
    }

    setState(() => _loading = false);
  }


  void _onSearchChanged(String query) {
    query = query.toLowerCase().trim();

    setState(() {
      if (query.isEmpty) {
        _filteredVendors = _allVendors;
      } else {
        _filteredVendors = _allVendors.where((v) {
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
            hintText: "Search store...",
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
          widget.categoryName,
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
                  : _filteredVendors.isEmpty
                  ? _StateMessage(
                icon: Icons.search_off,
                message: "No matching vendors",
              )
                  : ListView.separated(
            padding: const EdgeInsets.all(16),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        itemCount: _filteredVendors.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final vendor = _filteredVendors[index];

          return _VendorCard(
            vendor: vendor,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VendorProductsPage(
                    vendorId: vendor.id,
                    vendorName: vendor.name,
                    catergoryId: widget.categoryId,
                  ),
                ),
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




class _VendorCard extends StatelessWidget {
  final Vendor vendor;
  final VoidCallback onTap;

  const _VendorCard({
    required this.vendor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final image = vendor.images.isNotEmpty
        ? vendor.images.first
        : "https://picsum.photos/800/400";

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: StoreProfileTheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// 🖼 COVER IMAGE
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      image,
                      width: double.infinity,
                      fit: BoxFit.cover,
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

                  /// gradient overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.center,
                          colors: [
                            Colors.black.withValues(alpha: .35),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  /// Vendor name on image
                  Positioned(
                    left: 14,
                    bottom: 12,
                    right: 14,
                    child: Text(
                      vendor.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            /// 📄 DETAILS SECTION
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Row(
                children: [

                  /// small icon badge
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: StoreProfileTheme.lightPink.withValues(alpha: .35),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.storefront,
                        size: 20,
                        color: StoreProfileTheme.accentPink),
                  ),

                  const SizedBox(width: 12),


                  /// text info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // Text(
                        //   "Open Store",
                        //   style: GoogleFonts.poppins(
                        //     fontSize: 12,
                        //     color: Colors.grey[600],
                        //   ),
                        // ),

                        // const SizedBox(height: 2),

                        Text(
                          "Browse all products",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// arrow icon
                  Icon(Icons.arrow_forward_ios_rounded,
                      size: 18,
                      color: StoreProfileTheme.accentPink),
                ],
              ),
            ),
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
