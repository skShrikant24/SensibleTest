import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:GrabIt/pages/components/app_drawer.dart';
import 'package:GrabIt/pages/components/home_header.dart';
import 'package:GrabIt/pages/product_details_page.dart';
class StorePage extends StatelessWidget {
  final ValueChanged<int> onSelectTab;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  StorePage({super.key, required this.onSelectTab});

  final List<Map<String, dynamic>> products = [
    {
      'name': 'Disha Group T-Shirt',
      'price': 500,
      'image': 'assets/images/tshirt.png',
    },
    {
      'name': 'Disha Group Hoodie',
      'price': 500,
      'image': 'assets/images/hoodie.png',
    },
    {
      'name': 'Disha Group Cap',
      'price': 500,
      'image': 'assets/images/cap.png',
    },
    {
      'name': 'Disha Group Notebook',
      'price': 500,
      'image': 'assets/images/notebook.png',
    },
    {
      'name': 'Disha Group Pen',
      'price': 500,
      'image': 'assets/images/pen.png',
    },
    {
      'name': 'Disha Group Water Bottle',
      'price': 500,
      'image': 'assets/images/bottle.png',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF4F5F7),
      drawer: AppDrawer(onSelectTab: onSelectTab, currentTabIndex: 2),
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
                child: Image.asset(
                  'assets/images/store_banner.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // 🧭 Category Tabs
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  _CategoryTab(title: 'All', isActive: true),
                  _CategoryTab(title: 'Apparel'),
                  _CategoryTab(title: 'Accessories'),
                  _CategoryTab(title: 'Stationery'),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: Divider()),

          // 🛍️ Product Grid
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.80,
              ),
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final product = products[index];
                  return _ProductCard(
                    name: product['name'],
                    price: product['price'],
                    image: product['image'],
                  );
                },
                childCount: products.length,
              ),
            ),
          ),
          // 🟣 Banner Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/images/store_banner1.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          // 🟣 Banner Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/images/store_banner.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          // 🟣 Banner Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/images/coching.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }
}

// 🏷️ Category Tabs
class _CategoryTab extends StatelessWidget {
  final String title;
  final bool isActive;

  const _CategoryTab({required this.title, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
        color: isActive ? Colors.black : Colors.grey[600],
      ),
    );
  }
}

// 🛒 Product Card
class _ProductCard extends StatelessWidget {
  final String name;
  final int price;
  final String image;

  const _ProductCard({
    required this.name,
    required this.price,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // 👇 Navigate to Product Details Page when tapped
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailsPage(
              name: name,
              price: price.toDouble(),
              description:
              "Show your support for Disha Group with this stylish and comfortable t-shirt. Made from high-quality materials, it's perfect for everyday wear.",
              imageUrl: image,
              sizes: ["S", "M", "L", "XL"],
              colors: [Colors.black, Colors.white, Colors.blueAccent],
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🖼 Product Image
            Expanded(
              child: ClipRRect(
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(14)),
                child: Image.asset(
                  image,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹ $price',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.red[700],
                      fontWeight: FontWeight.w600,
                    ),
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
