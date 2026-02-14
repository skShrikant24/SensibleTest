import 'package:GraBiTT/Classes/Vender.dart';
import 'package:GraBiTT/Classes/vendor_product.dart';
import 'package:GraBiTT/pages/category_vendors_page.dart';
import 'package:GraBiTT/pages/vendor_products_page.dar.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:GraBiTT/pages/components/app_drawer.dart';
import 'package:GraBiTT/pages/product_details_page.dart';
import 'package:GraBiTT/pages/components/header_pill.dart';
import 'package:GraBiTT/pages/notification_page.dart';
import 'package:GraBiTT/pages/cart_page.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../Classes/Category.dart';
import '../Classes/product.dart';
import '../app_State/Cart.dart';
import '../utils/constants.dart';

class StorePage extends StatefulWidget {
  final ValueChanged<int> onSelectTab;
  /// Called with true when user scrolls down (hide bar), false when scrolls up (show bar).
  final ValueChanged<bool>? onScrollDirection;

  const StorePage({
    super.key,
    required this.onSelectTab,
    this.onScrollDirection,
  });

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String selectedCategory = 'all';
  String selectedLanguage = 'EN';
  bool _isVendorLoading = false;
  late Future<List<Category>> _categoriesFuture;
  late Future<List<Vendor>> _vendorsFuture;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  static const double _scrollThreshold = 10.0;
  double _lastScrollOffset = 0;

  /// When true, bottom nav is hidden (scrolled down) → buttons sit at very bottom.
  bool _bottomBarHidden = false;

  /// Cached so scrolling (rebuilds) doesn't create a new Future and refetch.
  late Future<List<Product>> _productsFuture;

  /// Slider images for the current category (getsilder API).
  late Future<List<String>> _sliderFuture;

  /// Approximate height of main_shell bottom bar (with padding) so buttons sit above it when visible.
  static const double _bottomBarHeight = 72;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _categoriesFuture = fetchCategories();
    // _vendorsFuture = fetchVendorsByCategory("all");
    // _productsFuture = fetchProducts(category: selectedCategory);
    // _sliderFuture = fetchSliderImages(selectedCategory);
  }


  void _onScroll() {
    final offset = _scrollController.offset;
    final delta = offset - _lastScrollOffset;
    if (delta > _scrollThreshold) {
      _lastScrollOffset = offset;
      setState(() => _bottomBarHidden = true);
      widget.onScrollDirection?.call(true); // scrolling down → hide bar
    } else if (delta < -_scrollThreshold) {
      _lastScrollOffset = offset;
      setState(() => _bottomBarHidden = false);
      widget.onScrollDirection?.call(false); // scrolling up → show bar
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: StoreProfileTheme.background,
      drawer: AppDrawer(onSelectTab: widget.onSelectTab, currentTabIndex: 2),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  // 🔝 Top Header Section
                  SliverToBoxAdapter(
                    child: _buildTopHeader(),
                  ),

                  // 🔍 Search Bar
                  SliverToBoxAdapter(
                    child: _buildSearchBar(),
                  ),

                  // 🏷️ Categories Section
                  SliverToBoxAdapter(
                    child: _buildCategoriesSection(),
                  ),

                  // 🎯 Recommended/Offers Section
                  // SliverToBoxAdapter(
                  //   child: _buildRecommendedSection(),
                  // ),

                  // 🛍️ Products Grid
                  // SliverPadding(
                  //   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  //   sliver: FutureBuilder<List<Product>>(
                  //     future: _productsFuture,
                  //     builder: (context, snapshot) {
                  //       if (snapshot.connectionState == ConnectionState.waiting) {
                  //         return const SliverToBoxAdapter(
                  //           child: Padding(
                  //             padding: EdgeInsets.only(top: 60),
                  //             child: Center(child: CircularProgressIndicator()),
                  //           ),
                  //         );
                  //       }
                  //
                  //       if (snapshot.hasError) {
                  //         return SliverToBoxAdapter(
                  //           child: Padding(
                  //             padding: const EdgeInsets.only(top: 80),
                  //             child: Center(
                  //               child: Text(
                  //                 "Something went wrong",
                  //                 style: GoogleFonts.poppins(color: Colors.grey),
                  //               ),
                  //             ),
                  //           ),
                  //         );
                  //       }
                  //
                  //       final products = snapshot.data ?? [];
                  //       if (products.isEmpty) {
                  //         return SliverToBoxAdapter(
                  //           child: Padding(
                  //             padding: const EdgeInsets.only(top: 80),
                  //             child: Column(
                  //               children: [
                  //                 Icon(
                  //                   Icons.inventory_2_outlined,
                  //                   size: 80,
                  //                   color: Colors.grey.shade400,
                  //                 ),
                  //                 const SizedBox(height: 12),
                  //                 Text(
                  //                   "No products found",
                  //                   style: GoogleFonts.poppins(
                  //                     fontSize: 16,
                  //                     color: Colors.grey.shade600,
                  //                   ),
                  //                 ),
                  //               ],
                  //             ),
                  //           ),
                  //         );
                  //       }
                  //
                  //       return SliverGrid(
                  //         gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  //           crossAxisCount: 2,
                  //           crossAxisSpacing: 12,
                  //           mainAxisSpacing: 12,
                  //           childAspectRatio: 0.80,
                  //         ),
                  //         delegate: SliverChildBuilderDelegate(
                  //           (context, index) {
                  //             final product = products[index];
                  //             return _ProductCard(product: product);
                  //           },
                  //           childCount: products.length,
                  //         ),
                  //       );
                  //     },
                  //   ),
                  // ),

                  SliverToBoxAdapter(
                    child:SizedBox(height: 50,),
                  ),


                  // 🔍 Bottom Search Section with Restaurant List
                  // SliverToBoxAdapter(
                  //   child: _buildBottomSearchSection(),
                  // ),
                  //
                  // const SliverToBoxAdapter(child: SizedBox(height: 20)),
                ],
              ),
            ),
            // 🚀 Fixed bottom: Pick & Deliver + Quick Order (sticky; when bottom bar hides, sits at bottom)
            _buildFixedActionButtons(),
          ],
        ),
      ),
    );
  }

  // 🔝 Top Header: Delivery info, Location, Language, Icons
  Widget _buildTopHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          // First Row: Delivery & Language
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Delivery Time
              Text(
                'Delivery in 15 mins',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.green[700],
                ),
              ),

              // Language Selection
              GestureDetector(
                onTap: () {
                  setState(() {
                    selectedLanguage = selectedLanguage == 'EN' ? 'HI' : 'EN';
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: StoreProfileTheme.lightPink.withValues(alpha: 0.5),
                    border: Border.all(color: StoreProfileTheme.border),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Text(
                        selectedLanguage,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        selectedLanguage == 'EN' ? 'हिन्दी' : 'EN',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Second Row: Location & Icons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Location
              GestureDetector(
                onTap: () {
                  // TODO: Open location selector
                },
                child: Row(
                  children: [
                    Text(
                      'Location',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
                  ],
                ),
              ),

              // Icons: Profile, Cart, Notification
              Row(
                children: [
                  // Profile/Points Icon
                  HeaderPill(
                    icon: Icons.person_outline,
                    text: '25',
                    onTap: () {
                      _scaffoldKey.currentState?.openDrawer();
                    },
                  ),
                  const SizedBox(width: 10),

                  // Cart Icon
                  AnimatedBuilder(
                    animation: CartService.instance,
                    builder: (context, _) {
                      return HeaderPill(
                        icon: Icons.shopping_cart_outlined,
                        badgeCount: CartService.instance.count,
                        shouldAnimate: CartService.instance.shouldAnimateCart,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CartPage()),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(width: 10),

                  // Notification Icon
                  HeaderPill(
                    icon: Icons.notifications_none_rounded,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NotificationsPage()),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 🔍 Search Bar
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        decoration: BoxDecoration(
          color: StoreProfileTheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: StoreProfileTheme.border.withValues(alpha: 0.2),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search for anything',
            hintStyle: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          style: GoogleFonts.poppins(fontSize: 14),
        ),
      ),
    );
  }

  // 🏷️ Categories Section: horizontal chips + grid of categories (image + name)
  Widget _buildCategoriesSection() {
    return FutureBuilder<List<Category>>(
      future: _categoriesFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final categories = snapshot.data!;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// CATEGORY CHIPS
              // SingleChildScrollView(
              //   scrollDirection: Axis.horizontal,
              //   child: Row(
              //     children: [
              //       _CategoryChip(
              //         title: 'All',
              //         isActive: selectedCategory == 'all',
              //         onTap: () => _selectCategory('all'),
              //       ),
              //       const SizedBox(width: 8),
              //
              //       ...categories.map((cat) => Padding(
              //         padding: const EdgeInsets.only(right: 8),
              //         child: _CategoryChip(
              //           title: cat.name,
              //           isActive: selectedCategory == cat.name,
              //           onTap: () => _selectCategory(cat.name),
              //         ),
              //       )),
              //     ],
              //   ),
              // ),
              //
              // const SizedBox(height: 16),

              /// VENDOR GRID (dynamic)
              _buildVendorGrid()
            ],
          ),
        );
      },
    );
  }

  Widget _buildVendorGrid() {

    return FutureBuilder<List<Category>>(
      future: _categoriesFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final categories = snapshot.data!;

        if (categories.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: Text("No vendors found")),
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: categories.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.82,
          ),
          itemBuilder: (context, index) {
            final vendor = categories[index];

            return _CategoryGridTile(
              label: vendor.name,
              imageUrl: vendor.imageUrl,
              isSelected: false,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CategoryVendorsPage(
                      categoryName: vendor.name,
                      categoryId: vendor.id,
                    ),
                  ),
                );
              },

            );
          },
        );
      },
    );
  }


  void _selectCategory(String name) async {
    setState(() {
      selectedCategory = name;
      _isVendorLoading = true;
    });

    final vendorsFuture = fetchVendorsByCategory(name);
    // final productsFuture = fetchProducts(category: name);
    // final sliderFuture = fetchSliderImages(name);

    final vendors = await vendorsFuture;

    setState(() {
      _vendorsFuture = Future.value(vendors);
      // _productsFuture = productsFuture;
      // _sliderFuture = sliderFuture;
      _isVendorLoading = false;
    });
  }



  // 🎯 Recommended/Offers Section (slider from getsilder API by category)
  Widget _buildRecommendedSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: StoreProfileTheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: StoreProfileTheme.border.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: FutureBuilder<List<String>>(
            future: _sliderFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  color: StoreProfileTheme.lightPink.withValues(alpha: 0.3),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                return Container(
                  color: Colors.grey[300],
                  child: Center(
                    child: Text(
                      snapshot.hasData && snapshot.data!.isEmpty
                          ? 'No slides for this category'
                          : 'Recommended / Offers',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                );
              }
              final urls = snapshot.data!;
              return PageView.builder(
                itemCount: urls.length,
                itemBuilder: (context, index) {
                  final fullUrl = urls[index];
                  return Image.network(
                    fullUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: Center(
                          child: Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey[600]),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  // 🚀 Fixed bottom action buttons: Pick & Deliver, Quick Order (sticky when bottom bar hides)
  Widget _buildFixedActionButtons() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        _bottomBarHidden ? 16 : 12 + _bottomBarHeight,
      ),
      decoration: BoxDecoration(
        color: StoreProfileTheme.surface,
        boxShadow: [
          BoxShadow(
            color: StoreProfileTheme.border.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: double.infinity,
            child: _ActionButton(
              title: 'Pick & Deliver',
              icon: Icons.local_shipping_outlined,
              onTap: () {
                // TODO: Navigate to Pick & Deliver page
              },
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: _ActionButton(
              title: 'Quick order',
              icon: Icons.flash_on,
              onTap: () {
                // TODO: Navigate to Quick Order page
              },
            ),
          ),
        ],
      ),
    );
  }

  // 🔍 Bottom Search Section with Restaurant List
  Widget _buildBottomSearchSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: StoreProfileTheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: StoreProfileTheme.border.withValues(alpha: 0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: _getSearchPlaceholder(),
                hintStyle: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              style: GoogleFonts.poppins(fontSize: 14),
              onChanged: (value) {
                setState(() {
                  // Trigger search/filter
                });
              },
            ),
          ),

          const SizedBox(height: 20),

          // Restaurant List
          FutureBuilder<List<Restaurant>>(
            future: fetchRestaurantsByCategory(selectedCategory),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      "Failed to load restaurants",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                );
              }

              final restaurants = snapshot.data ?? [];
              if (restaurants.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      "No restaurants found",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: restaurants.map((restaurant) {
                  return _RestaurantListItem(
                    restaurant: restaurant,
                    onViewAllItems: () {
                      // TODO: Navigate to restaurant items page
                      // Navigator.push(
                      //   context,
                      //   MaterialPageRoute(
                      //     builder: (_) => RestaurantItemsPage(restaurantId: restaurant.id),
                      //   ),
                      // );
                    },
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  String _getSearchPlaceholder() {
    switch (selectedCategory.toLowerCase()) {
      case 'restaurant':
        return 'Search for Restaurants';
      case 'grocery stores':
      case 'grocery':
        return 'Search for Grocery Stores';
      case 'medical':
      case 'pharmacy':
        return 'Search for Medical Stores';
      default:
        return 'Search for anything';
    }
  }
}

// 🏷️ Category Chip Widget
class _CategoryChip extends StatelessWidget {
  final String title;
  final bool isActive;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.title,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? StoreProfileTheme.lightPink : StoreProfileTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? StoreProfileTheme.accentPink : StoreProfileTheme.border,
            width: 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: StoreProfileTheme.border.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isActive ? StoreProfileTheme.accentPink : Colors.black87,
          ),
        ),
      ),
    );
  }
}

// 🏷️ Category grid tile: image + name (like reference layout)
class _CategoryGridTile extends StatelessWidget {
  final String label;
  final String? imageUrl;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryGridTile({
    required this.label,
    required this.imageUrl,
    required this.isSelected,
    required this.onTap,
  });

  static const String _placeholder = 'https://picsum.photos/400/400';

  @override
  Widget build(BuildContext context) {
    final url = (imageUrl != null && imageUrl!.trim().isNotEmpty)
        ? imageUrl!
        : _placeholder;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: StoreProfileTheme.border.withValues(alpha: 0.15),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
          border: isSelected
              ? Border.all(color: StoreProfileTheme.accentPink, width: 2)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                // borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  url,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (_, __, ___) => Image.network(
                    _placeholder,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 🚀 Action Button Widget
class _ActionButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          gradient: StoreProfileTheme.secondaryGradient,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: StoreProfileTheme.border),
          boxShadow: [
            BoxShadow(
              color: StoreProfileTheme.accentPink.withValues(alpha: 0.15),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: StoreProfileTheme.accentPink),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 🛒 Product Card
class _ProductCard extends StatelessWidget {
  final Product product;

  const _ProductCard({
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailsPage(product: product),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: StoreProfileTheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: StoreProfileTheme.border.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🖼 Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                product.productImage.isNotEmpty
                    ? "https://grabitt.in/${product.productImage}"
                    : "https://picsum.photos/400/400",
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Image.network(
                    "https://picsum.photos/400/400",
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 150,
                        width: double.infinity,
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                          size: 40,
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        "₹${product.discountPrice}",
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "₹${product.originalPrice}",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 🌐 API Functions
Future<List<Category>> fetchCategories() async {
  final response = await http.get(
    Uri.parse('https://grabitt.in/webservice.asmx/GetCategory'),
  );

  if (response.statusCode == 200) {
    final jsonString = response.body.replaceAll(RegExp(r'<[^>]*>'), '');
    final List data = json.decode(jsonString);
    return data.map((e) => Category.fromJson(e)).toList();
  } else {
    throw Exception('Failed to load categories');
  }
}

Future<List<Vendor>> fetchVendors() async {
  final response = await http.get(
    Uri.parse('https://grabitt.in/webservice.asmx/GetVendorsCategoryWiseImages?CategoryName=all'),
  );

  if (response.statusCode == 200) {

    final jsonString = response.body.replaceAll(RegExp(r'<[^>]*>'), '');
    final List data = json.decode(jsonString);

    final vendors = data.map((e) => Vendor.fromJson(e)).toList();

    print("__________________");
    print(vendors);

    return vendors;
  } else {
    throw Exception('Failed to load vendors');
  }
}

Future<List<Vendor>> fetchVendorsByCategory(String category) async {
  try {
    final url =
        'https://grabitt.in/webservice.asmx/GetVendorsCategoryWiseImages?CategoryName=${Uri.encodeComponent(category)}';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode != 200) return [];

    /// Remove XML wrapper
    final cleaned = response.body
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .trim();

    print("VENDOR API RAW => $cleaned");

    /// 🚨 HANDLE NON JSON RESPONSES
    if (cleaned.isEmpty ||
        cleaned.toLowerCase() == 'no data' ||
        cleaned.toLowerCase() == 'fail' ||
        cleaned == 'null') {
      return [];
    }

    /// Sometimes API returns single object instead of array
    dynamic decoded = json.decode(cleaned);

    if (decoded is List) {
      return decoded.map((e) => Vendor.fromJson(e)).toList();
    }

    if (decoded is Map) {
      final map = Map<String, dynamic>.from(decoded);
      return [Vendor.fromJson(map)];
    }


    return [];
  } catch (e) {
    print("Vendor Parse Error => $e");
    return [];
  }
}

Future<List<Product>> fetchProducts({String? category}) async {
  final url = category == null || category == 'All'
      ? 'https://grabitt.in/webservice.asmx/GetProductsByCategory?category=ALL'
      : 'https://grabitt.in/webservice.asmx/GetProductsByCategory?category=${Uri.encodeComponent(category)}';

  final response = await http.get(Uri.parse(url));

  if (response.statusCode == 200) {
    final cleaned = response.body.replaceAll(RegExp(r'<[^>]*>'), '').trim();

    if (cleaned.toLowerCase() == 'fail' || cleaned.isEmpty) {
      return [];
    }

    try {
      final List data = json.decode(cleaned);
      return data.map((e) => Product.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  } else {
    return [];
  }
}

/// Fetches slider image URLs for the given category.
/// API: GET https://grabitt.in/webservice.asmx/getsilder?category=string
Future<List<String>> fetchSliderImages(String category) async {
  final url = category == 'All' || category.isEmpty
      ? 'https://grabitt.in/webservice.asmx/getsilder?category=ALL'
      : 'https://grabitt.in/webservice.asmx/getsilder?category=${Uri.encodeComponent(category)}';

  try {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode != 200) return [];

    final cleaned = response.body.replaceAll(RegExp(r'<[^>]*>'), '').trim();
    if (cleaned.toLowerCase() == 'fail' || cleaned.isEmpty) return [];

    final decoded = json.decode(cleaned);

    if (decoded is! List) return [];

    const String uploadsBase = 'https://grabitt.in/uploads/';
    final List<String> urls = [];
    for (final item in decoded) {
      if (item is String) {
        if (item.trim().isNotEmpty) {
          final name = item.trim();
          urls.add(name.startsWith('http') ? name : '$uploadsBase${Uri.encodeComponent(name)}');
        }
      } else if (item is Map) {
        // API returns: {"Id":"1","Category":"Restaurants","Images":"1.jpg",...}
        final raw = item['Images'] ?? item['image'] ?? item['Image'] ?? item['SliderImage'] ?? item['url'] ?? item['path'] ?? item['sliderimage'];
        if (raw != null && raw.toString().trim().isNotEmpty) {
          final imageName = raw.toString().trim();
          final fullUrl = imageName.startsWith('http') ? imageName : '$uploadsBase${Uri.encodeComponent(imageName)}';
          urls.add(fullUrl);
        }
      }
    }
    return urls;
  } catch (e) {
    return [];
  }
}

// 🏪 Restaurant Model
class Restaurant {
  final String id;
  final String name;
  final String category;
  final String? imageUrl;
  final double? rating;
  final String? address;

  Restaurant({
    required this.id,
    required this.name,
    required this.category,
    this.imageUrl,
    this.rating,
    this.address,
  });

  // Factory constructor for API response (future use)
  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['RestaurantID'] ?? json['id'] ?? '',
      name: json['RestaurantName'] ?? json['name'] ?? '',
      category: json['Category'] ?? json['category'] ?? '',
      imageUrl: json['ImageUrl'] ?? json['imageUrl'],
      rating: json['Rating'] != null ? double.tryParse(json['Rating'].toString()) : null,
      address: json['Address'] ?? json['address'],
    );
  }

  // Convert to JSON for API calls (future use)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'imageUrl': imageUrl,
      'rating': rating,
      'address': address,
    };
  }
}

// 🏪 Restaurant List Item Widget
class _RestaurantListItem extends StatelessWidget {
  final Restaurant restaurant;
  final VoidCallback onViewAllItems;

  const _RestaurantListItem({
    required this.restaurant,
    required this.onViewAllItems,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Restaurant Name
          Expanded(
            child: Text(
              restaurant.name,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // View All Items Link
          GestureDetector(
            onTap: onViewAllItems,
            child: Text(
              'View all items',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: StoreProfileTheme.accentPink,
                decoration: TextDecoration.underline,
                decorationColor: StoreProfileTheme.accentPink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 🌐 API Function for Restaurants (Production Ready)
Future<List<Restaurant>> fetchRestaurantsByCategory(String category) async {
  // TODO: Replace with actual API call when backend is ready
  // Example API endpoint: 'https://grabitt.in/webservice.asmx/GetRestaurantsByCategory?category=${Uri.encodeComponent(category)}'
  
  // For now, return dummy data based on category
  return _getDummyRestaurants(category);

  /* 
  // Uncomment when API is ready:
  try {
    final url = category == 'All' || category.isEmpty
        ? 'https://grabitt.in/webservice.asmx/GetRestaurantsByCategory?category=ALL'
        : 'https://grabitt.in/webservice.asmx/GetRestaurantsByCategory?category=${Uri.encodeComponent(category)}';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final cleaned = response.body.replaceAll(RegExp(r'<[^>]*>'), '').trim();

      if (cleaned.toLowerCase() == 'fail' || cleaned.isEmpty) {
        return [];
      }

      try {
        final List data = json.decode(cleaned);
        return data.map((e) => Restaurant.fromJson(e)).toList();
      } catch (e) {
        // If JSON parsing fails, return empty list
        return [];
      }
    } else {
      return [];
    }
  } catch (e) {
    // Handle network errors gracefully
    return [];
  }
  */
}

// 📦 Dummy Data Generator (Replace with API call)
List<Restaurant> _getDummyRestaurants(String category) {
  // Simulate API delay
  // In production, this will be replaced by actual API call

  final categoryLower = category.toLowerCase();
  
  // Generate dummy restaurants based on category
  if (categoryLower == 'all' || categoryLower.isEmpty) {
    return List.generate(4, (index) => Restaurant(
      id: 'rest_${index + 1}',
      name: 'Restaurant ${index + 1}',
      category: 'Restaurant',
      rating: 4.0 + (index * 0.2),
    ));
  } else if (categoryLower.contains('restaurant')) {
    return List.generate(4, (index) => Restaurant(
      id: 'rest_${index + 1}',
      name: 'Restaurant ${index + 1}',
      category: 'Restaurant',
      rating: 4.0 + (index * 0.2),
    ));
  } else if (categoryLower.contains('grocery')) {
    return List.generate(3, (index) => Restaurant(
      id: 'grocery_${index + 1}',
      name: 'Grocery Store ${index + 1}',
      category: 'Grocery',
      rating: 4.2 + (index * 0.1),
    ));
  } else if (categoryLower.contains('medical') || categoryLower.contains('pharmacy')) {
    return List.generate(3, (index) => Restaurant(
      id: 'medical_${index + 1}',
      name: 'Medical Store ${index + 1}',
      category: 'Medical',
      rating: 4.5 + (index * 0.1),
    ));
  } else {
    // Default: return restaurants for any other category
    return List.generate(2, (index) => Restaurant(
      id: 'store_${index + 1}',
      name: '${category} Store ${index + 1}',
      category: category,
      rating: 4.0,
    ));
  }
}
