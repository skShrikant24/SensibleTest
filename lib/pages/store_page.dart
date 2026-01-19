import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:GraBiTT/pages/components/app_drawer.dart';
import 'package:GraBiTT/pages/components/home_header.dart';
import 'package:GraBiTT/pages/product_details_page.dart';
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

// 🏷️ Category Tabs with Animated Icons
class _CategoryTab extends StatefulWidget {
  final String title;
  final bool isActive;
  final VoidCallback onTap;

  const _CategoryTab({
    required this.title,
    required this.onTap,
    this.isActive = false,
  });

  @override
  State<_CategoryTab> createState() => _CategoryTabState();
}

class _CategoryTabState extends State<_CategoryTab> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: widget.isActive ? Colors.black : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: widget.isActive ? Colors.black : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated Icon
            SizedBox(
              width: 20,
              height: 20,
              child: _AnimatedCategoryIcon(
                categoryName: widget.title,
                isActive: widget.isActive,
              ),
            ),
            const SizedBox(width: 8),
            // Category Name
            Text(
              widget.title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: widget.isActive ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 🎬 Animated Category Icon Widget
class _AnimatedCategoryIcon extends StatefulWidget {
  final String categoryName;
  final bool isActive;

  const _AnimatedCategoryIcon({
    required this.categoryName,
    this.isActive = false,
  });

  @override
  State<_AnimatedCategoryIcon> createState() => _AnimatedCategoryIconState();
}

class _AnimatedCategoryIconState extends State<_AnimatedCategoryIcon>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  CategoryAnimationType? _animationType;

  @override
  void initState() {
    super.initState();
    _animationType = _getAnimationType(widget.categoryName);
    _setupAnimation();
  }

  CategoryAnimationType? _getAnimationType(String categoryName) {
    final name = categoryName.toLowerCase();
    if (name.contains('food') || name.contains('restaurant') || name.contains('meal')) {
      return CategoryAnimationType.food;
    } else if (name.contains('grocery') || name.contains('groc')) {
      return CategoryAnimationType.grocery;
    } else if (name.contains('pesticide') || name.contains('agri') || name.contains('agriculture') || name.contains('farm')) {
      return CategoryAnimationType.pesticides;
    } else if (name.contains('pharmacy') || name.contains('medicine') || name.contains('medical')) {
      return CategoryAnimationType.pharmacy;
    }
    return null;
  }

  void _setupAnimation() {
    switch (_animationType) {
      case CategoryAnimationType.food:
        // Steam cloud animation - repeats every 5 seconds
        _controller = AnimationController(
          vsync: this,
          duration: const Duration(seconds: 5),
        )..repeat();
        break;
      case CategoryAnimationType.grocery:
        // Bag handles lift - gentle up and down
        _controller = AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 1500),
        )..repeat(reverse: true);
        break;
      case CategoryAnimationType.pesticides:
        // Leaf wiggle - shake motion
        _controller = AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 800),
        )..repeat(reverse: true);
        break;
      case CategoryAnimationType.pharmacy:
        // Pill rotation - slow 360 degrees
        _controller = AnimationController(
          vsync: this,
          duration: const Duration(seconds: 4),
        )..repeat();
        break;
      case null:
        _controller = AnimationController(
          vsync: this,
          duration: const Duration(seconds: 1),
        );
        break;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = widget.isActive ? Colors.white : null;
    
    if (_animationType == null) {
      return Icon(Icons.category, size: 20, color: iconColor);
    }

    switch (_animationType!) {
      case CategoryAnimationType.food:
        return _FoodSteamAnimation(
          controller: _controller,
          iconColor: iconColor,
        );
      case CategoryAnimationType.grocery:
        return _GroceryBagAnimation(
          controller: _controller,
          iconColor: iconColor,
        );
      case CategoryAnimationType.pesticides:
        return _LeafWiggleAnimation(
          controller: _controller,
          iconColor: iconColor,
        );
      case CategoryAnimationType.pharmacy:
        return _PillRotationAnimation(
          controller: _controller,
          iconColor: iconColor,
        );
    }
  }
}

enum CategoryAnimationType {
  food,
  grocery,
  pesticides,
  pharmacy,
}

// 🍜 Food: Steam Cloud Animation
class _FoodSteamAnimation extends StatelessWidget {
  final AnimationController controller;
  final Color? iconColor;

  const _FoodSteamAnimation({
    required this.controller,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        // Steam rises and fades - appears every 5 seconds
        final cycleValue = controller.value;
        final steamOpacity = cycleValue < 0.4
            ? Tween<double>(begin: 0.0, end: 0.8).transform(cycleValue / 0.4)
            : cycleValue < 0.6
                ? Tween<double>(begin: 0.8, end: 0.0).transform((cycleValue - 0.4) / 0.2)
                : 0.0;
        
        final steamOffset = cycleValue < 0.4
            ? Tween<double>(begin: 0.0, end: -10.0).transform(cycleValue / 0.4)
            : cycleValue < 0.6
                ? Tween<double>(begin: -10.0, end: -15.0).transform((cycleValue - 0.4) / 0.2)
                : 0.0;

        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Bowl/food icon
            Icon(
              Icons.ramen_dining,
              size: 20,
              color: iconColor ?? Colors.orange,
            ),
            // Steam cloud - only visible during animation cycle
            if (cycleValue < 0.6 && steamOpacity > 0)
              Positioned(
                top: steamOffset - 8,
                child: Opacity(
                  opacity: steamOpacity,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.grey[200]?.withOpacity(0.7),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey[300]!.withOpacity(0.5),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.cloud,
                      size: 10,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// 🛒 Grocery: Bag Handles Lift Animation
class _GroceryBagAnimation extends StatelessWidget {
  final AnimationController controller;
  final Color? iconColor;

  const _GroceryBagAnimation({
    required this.controller,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        // Handles lift up and down - gentle motion as if being picked up
        final liftOffset = Tween<double>(begin: 0.0, end: -4.0).animate(
          CurvedAnimation(
            parent: controller,
            curve: Curves.easeInOut,
          ),
        ).value;

        return Transform.translate(
          offset: Offset(0, liftOffset),
          child: Icon(
            Icons.shopping_bag,
            size: 20,
            color: iconColor ?? Colors.brown,
          ),
        );
      },
    );
  }
}

// 🌿 Pesticides/Agri: Leaf Wiggle Animation
class _LeafWiggleAnimation extends StatelessWidget {
  final AnimationController controller;
  final Color? iconColor;

  const _LeafWiggleAnimation({
    required this.controller,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        // Leaf wiggles left and right to shake off water drop
        final wiggleAngle = Tween<double>(begin: -0.2, end: 0.2).animate(
          CurvedAnimation(
            parent: controller,
            curve: Curves.elasticOut,
          ),
        ).value;

        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Transform.rotate(
              angle: wiggleAngle,
              child: Icon(
                Icons.eco,
                size: 20,
                color: iconColor ?? Colors.green,
              ),
            ),
            // Water drop that falls off
            if (controller.value > 0.5 && controller.value < 0.7)
              Positioned(
                top: 12,
                left: 8,
                child: Opacity(
                  opacity: 1.0 - ((controller.value - 0.5) / 0.2),
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// 💊 Pharmacy: Pill Rotation Animation
class _PillRotationAnimation extends StatelessWidget {
  final AnimationController controller;
  final Color? iconColor;

  const _PillRotationAnimation({
    required this.controller,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        // Gentle slow 360-degree rotation
        return Transform.rotate(
          angle: controller.value * 2 * 3.14159,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: iconColor != null ? Colors.transparent : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: iconColor ?? Colors.blue.shade400,
                width: 1.5,
              ),
              boxShadow: iconColor == null
                  ? [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.2),
                        blurRadius: 4,
                        spreadRadius: 0.5,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              Icons.medication,
              size: 12,
              color: iconColor ?? Colors.blue,
            ),
          ),
        );
      },
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
