import 'package:GraBiTT/app_State/locale_provider.dart';
import 'package:GraBiTT/l10n/app_localizations.dart';
import 'package:GraBiTT/models/vender.dart';
import 'package:GraBiTT/pages/store_page.dart';
import 'package:GraBiTT/pages/vendor_products_page.dart';
import 'package:GraBiTT/utils/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
      final lang = LocaleProvider.instance.languageCode;
      final vendors = await fetchVendorsByCategory(widget.categoryId, lang);
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
            hintText: AppLocalizations.of(context)!.searchStore,
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
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          itemCount: _filteredVendors.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 16),
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

  // Future<void> _callVendor(String mobile) async {
  //   final Uri url = Uri(scheme: 'tel', path: mobile);
  //   if (await canLaunchUrl(url)) {
  //     await launchUrl(url);
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final image = vendor.images.isNotEmpty
        ? vendor.images.first
        : "https://picsum.photos/800/400";

    return InkWell(
      borderRadius: BorderRadius.circular(20),

      /// UPDATED
      onTap: vendor.shopStatus ? onTap : null,
      child: Opacity(
        opacity: vendor.shopStatus ? 1 : 0.75,
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
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                child: Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: image.isEmpty
                          ? Container(
                              color: StoreProfileTheme.lightPink
                                  .withValues(alpha: .25),
                              child: Center(
                                child: Icon(
                                  Icons.store,
                                  size: 48,
                                  color: StoreProfileTheme.accentPink,
                                ),
                              ),
                            )
                          : CachedNetworkImage(
                              imageUrl: image,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              fadeInDuration: const Duration(milliseconds: 150),
                              memCacheWidth: 700,
                              maxWidthDiskCache: 900,
                              placeholder: (context, url) {
                                return Container(
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                );
                              },
                              errorWidget: (context, url, error) {
                                return Container(
                                  color: StoreProfileTheme.lightPink
                                      .withValues(alpha: .25),
                                  child: Center(
                                    child: Icon(
                                      Icons.broken_image_outlined,
                                      size: 48,
                                      color: StoreProfileTheme.accentPink,
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),

                    /// gradient overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20)),
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

                    /// NEW CLOSED OVERLAY
                    if (!vendor.shopStatus)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                            color: Colors.black.withValues(alpha: .35),
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

                    /// NEW CLOSED BADGE
                    if (!vendor.shopStatus)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "Closed",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
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
                        color:
                            StoreProfileTheme.lightPink.withValues(alpha: .35),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.storefront,
                          size: 20, color: StoreProfileTheme.accentPink),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                vendor.shopStatus
                                    ? Icons.access_time_rounded
                                    : Icons.cancel_rounded,
                                size: 16,
                                color: vendor.shopStatus
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: vendor.shopStatus
                                            ? "Open Store Time: "
                                            : "",
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      TextSpan(
                                        text: vendor.shopStatus
                                            ? "${vendor.openingTime} - ${vendor.closingTime}"
                                            : "Shop Closed",
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: vendor.shopStatus
                                              ? StoreProfileTheme.accentPink
                                              : Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          /// 📞 MOBILE + CALL BUTTON
                          // Row(
                          //   children: [
                          //     Expanded(
                          //       child: Text(
                          //         "Mobile No: ${vendor.mobileNo.isNotEmpty
                          //             ? vendor.mobileNo
                          //             : "No contact"}",
                          //         style: GoogleFonts.poppins(
                          //           fontSize: 13,
                          //           fontWeight: FontWeight.w500,
                          //         ),
                          //       ),
                          //     ),

                          //     if (vendor.mobileNo.isNotEmpty)
                          //       InkWell(
                          //         onTap: () => _callVendor(vendor.mobileNo),
                          //         child: Container(
                          //           padding: const EdgeInsets.all(6),
                          //           decoration: BoxDecoration(
                          //             color: Colors.green,
                          //             borderRadius: BorderRadius.circular(6),
                          //           ),
                          //           child: const Icon(
                          //             Icons.call,
                          //             color: Colors.white,
                          //             size: 16,
                          //           ),
                          //         ),
                          //       ),
                          //   ],
                          // ),

                          // const SizedBox(height: 4),
                          //
                          // Text(
                          //   AppLocalizations.of(context)!.browseAllProducts,
                          //   style: GoogleFonts.poppins(
                          //     fontSize: 14,
                          //     fontWeight: FontWeight.w500,
                          //   ),
                          // ),
                        ],
                      ),
                    ),

                    /// text info
                    // Expanded(
                    //   child: Column(
                    //     crossAxisAlignment: CrossAxisAlignment.start,
                    //     children: [
                    //       Text(
                    //         "Open Store Time: ${vendor?.OpeningTime ?? 'N/A'} to ${vendor?.ClosingTime ?? 'N/A'}",
                    //         style: GoogleFonts.poppins(
                    //           fontSize: 12,
                    //           color: Colors.grey[600],
                    //         ),
                    //       ),
                    //       const SizedBox(height: 2),
                    //
                    //       Text(
                    //         AppLocalizations.of(context)!.browseAllProducts,
                    //         style: GoogleFonts.poppins(
                    //           fontSize: 14,
                    //           fontWeight: FontWeight.w500,
                    //         ),
                    //       ),
                    //     ],
                    //   ),
                    // ),

                    /// arrow icon
                    // Icon(Icons.arrow_forward_ios_rounded,
                    //     size: 18,
                    //     color: StoreProfileTheme.accentPink),
                  ],
                ),
              ),
            ],
          ),
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
