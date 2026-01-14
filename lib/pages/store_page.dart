import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:GrabIt/pages/components/app_drawer.dart';
import 'package:GrabIt/pages/components/home_header.dart';
import 'package:GrabIt/pages/product_details_page.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../Classes/Category.dart';
import '../Classes/product.dart';

class StorePage extends StatefulWidget {
  final ValueChanged<int> onSelectTab;
  const StorePage({super.key, required this.onSelectTab});

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String selectedCategory = 'All';



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF4F5F7),
      //drawer: AppDrawer(onSelectTab: onSelectTab, currentTabIndex: 2),
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // 🔝 Header with Drawer Button
          SliverToBoxAdapter(
            child: HomeHeader(
              onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
              showGreeting: false, // no greeting on store page
            ),
          ),

          // 🟣 Banner Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 160,
                  child: PageView(
                    children: [
                      Image.asset('assets/images/slider.jpg', fit: BoxFit.cover),
                      Image.asset('assets/images/slide1.jpg', fit: BoxFit.cover),
                      Image.asset('assets/images/slide2.jpg', fit: BoxFit.cover),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // 🧭 Category Tabs
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FutureBuilder<List<Category>>(
                future: fetchCategories(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox(
                      height: 40,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final categories = snapshot.data!;

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _CategoryTab(
                          title: 'All',
                          isActive: selectedCategory == 'All',
                          onTap: () => setState(() => selectedCategory = 'All'),
                        ),
                        ...categories.map(
                              (cat) => _CategoryTab(
                            title: cat.name,
                            isActive: selectedCategory == cat.name,
                            onTap: () =>
                                setState(() => selectedCategory = cat.name),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),


          const SliverToBoxAdapter(child: Divider()),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: FutureBuilder<List<Product>>(
              future: fetchProducts(category: selectedCategory),
              builder: (context, snapshot) {

                // 🔄 Loading
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(top: 60),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  );
                }

                // ❌ Error
                if (snapshot.hasError) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 80),
                      child: Center(
                        child: Text(
                          "Something went wrong",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  );
                }

                // 📭 No data OR FAIL
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

                // 🛍️ Product Grid
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

          // 🟣 Banner Section



        ],

      ),
    );
  }

}

// 🏷️ Category Tabs
class _CategoryTab extends StatelessWidget {
  final String title;
  final bool isActive;
  final VoidCallback onTap;

  const _CategoryTab({
    required this.title,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.black : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? Colors.black : Colors.grey.shade300,
          ),
        ),
        child: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isActive ? Colors.white : Colors.black87,
          ),
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
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                "https://grabitt.in/${product.productImage}",
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
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





Future<List<Category>> fetchCategories() async {
  final response = await http.get(
    Uri.parse('https://grabitt.in/webservice.asmx/GetCategory'),
  );

  if (response.statusCode == 200) {
    // Remove XML wrapper
    final jsonString = response.body
        .replaceAll(RegExp(r'<[^>]*>'), '');

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
    // Remove XML tags
    final cleaned = response.body.replaceAll(RegExp(r'<[^>]*>'), '').trim();

    // 👇 Handle FAIL response
    if (cleaned.toLowerCase() == 'fail' || cleaned.isEmpty) {
      return [];
    }

    try {
      final List data = json.decode(cleaned);
      return data.map((e) => Product.fromJson(e)).toList();
    } catch (e) {
      // If JSON parsing fails
      return [];
    }
  } else {
    return [];
  }
}
