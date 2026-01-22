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

class StorePage extends StatefulWidget {
  final ValueChanged<int> onSelectTab;
  const StorePage({super.key, required this.onSelectTab});

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String selectedCategory = 'All';
  String selectedLanguage = 'EN';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawer: AppDrawer(onSelectTab: widget.onSelectTab, currentTabIndex: 2),
      body: SafeArea(
        child: CustomScrollView(
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
            SliverToBoxAdapter(
              child: _buildRecommendedSection(),
            ),

            // 🛍️ Products Grid
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: FutureBuilder<List<Product>>(
                future: fetchProducts(category: selectedCategory),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(top: 60),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 80),
                        child: Center(
                          child: Text(
                            "Something went wrong",
                            style: GoogleFonts.poppins(color: Colors.grey),
                          ),
                        ),
                      ),
                    );
                  }

                  final products = snapshot.data ?? [];
                  if (products.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 80),
                        child: Column(
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 80,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "No products found",
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.80,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final product = products[index];
                        return _ProductCard(product: product);
                      },
                      childCount: products.length,
                    ),
                  );
                },
              ),
            ),

            // 🚀 Action Buttons Section
            SliverToBoxAdapter(
              child: _buildActionButtons(),
            ),

            // 🔍 Bottom Search Section with Restaurant List
            SliverToBoxAdapter(
              child: _buildBottomSearchSection(),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),
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
                    border: Border.all(color: Colors.grey.shade300),
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
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
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

  // 🏷️ Categories Section
  Widget _buildCategoriesSection() {
    return FutureBuilder<List<Category>>(
      future: fetchCategories(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SizedBox(
              height: 40,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final categories = snapshot.data!;
        final mainCategories = ['Restaurant', 'Grocery Stores', 'Medical'];

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ALL label pointing to Restaurant
              // Row(
              //   children: [
              //     Text(
              //       'ALL',
              //       style: GoogleFonts.poppins(
              //         fontSize: 12,  
              //         fontWeight: FontWeight.w600,
              //         color: Colors.grey[600],
              //       ),
              //     ),
              //     const SizedBox(width: 4),
              //     const Icon(Icons.arrow_right, size: 16, color: Colors.grey),
              //     const SizedBox(width: 8),
              //     Text(
              //       'Restaurant',
              //       style: GoogleFonts.poppins(
              //         fontSize: 14,
              //         fontWeight: FontWeight.w600,
              //       ),
              //     ),
              //   ],
              // ),
              // const SizedBox(height: 12),

              // Category Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _CategoryChip(
                      title: 'All',
                      isActive: selectedCategory == 'All',
                      onTap: () => setState(() => selectedCategory = 'All'),
                    ),
                    const SizedBox(width: 8),
                    ...categories.map((cat) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _CategoryChip(
                            title: cat.name,
                            isActive: selectedCategory == cat.name,
                            onTap: () => setState(() => selectedCategory = cat.name),
                          ),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Home label (underlined)
              // Text(
              //   'Home',
              //   style: GoogleFonts.poppins(
              //     fontSize: 13,
              //     fontWeight: FontWeight.w500,
              //     decoration: TextDecoration.underline,
              //     color: Colors.grey[700],
              //   ),
              // ),
            ],
          ),
        );
      },
    );
  }

  // 🎯 Recommended/Offers Section
  Widget _buildRecommendedSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: PageView(
            children: [
              Image.asset(
                'assets/images/slider.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: Center(
                      child: Text(
                        'Recommended Section / Offers',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  );
                },
              ),
              Image.asset(
                'assets/images/slide1.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(color: Colors.grey[300]);
                },
              ),
              Image.asset(
                'assets/images/slide2.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(color: Colors.grey[300]);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🚀 Action Buttons: Pick & Deliver, Quick Order
  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: _ActionButton(
              title: 'Pick & Deliver',
              icon: Icons.local_shipping_outlined,
              onTap: () {
                // TODO: Navigate to Pick & Deliver page
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
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
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
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
          color: isActive ? Colors.black : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? Colors.black : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isActive ? Colors.white : Colors.black87,
          ),
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
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: Colors.redAccent),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
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
                    : "https://placehold.co/400x400.png",
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Image.network(
                    "https://placehold.co/400x400.png",
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
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        "₹${product.discountPrice.toInt()}",
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "₹${product.originalPrice.toInt()}",
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
                color: Colors.blue[700],
                decoration: TextDecoration.underline,
                decorationColor: Colors.blue[700],
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
