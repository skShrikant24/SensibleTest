import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:GraBiTT/pages/components/app_drawer.dart';
import 'package:GraBiTT/pages/cart_page.dart';
import 'package:GraBiTT/app_State/Cart.dart';
import 'package:GraBiTT/pages/components/header_pill.dart';
import 'package:GraBiTT/pages/notification_page.dart';

/// Yellow/grocery-style home screen matching the reference design:
/// Header (delivery, location, search, category tabs), category grid,
/// Morning Essentials row, bottom fee bar + CTA.
class HomePage extends StatefulWidget {
  HomePage({super.key, required this.onSelectTab});
  final ValueChanged<int> onSelectTab;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  String _selectedTab = 'All';
  String _selectedLanguage = 'EN';

  static const Color _yellow = Color(0xFFFFC107);
  static const Color _yellowDark = Color(0xFFF9A825);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _yellow,
      drawer: AppDrawer(onSelectTab: widget.onSelectTab, currentTabIndex: 0),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader()),
                  SliverToBoxAdapter(child: _buildSearchBar()),
                  SliverToBoxAdapter(child: _buildCategoryTabs()),
                  SliverToBoxAdapter(child: _buildCategoryGrid()),
                  SliverToBoxAdapter(child: _buildMorningEssentials()),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                ],
              ),
            ),
            Container(
              color: _yellow,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildBottomFeeBar(),
                  const SizedBox(height: 12),
                  _buildCtaButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.local_shipping_outlined, size: 20, color: Colors.black87),
                  const SizedBox(width: 6),
                  Text(
                    'Delivery in 12 mins',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedLanguage = _selectedLanguage == 'EN' ? 'ಕನ್' : 'EN';
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'EN',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'ಕನ್',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {},
                child: Row(
                  children: [
                    Text(
                      'Ashok Nagar',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right, size: 20, color: Colors.black87),
                  ],
                ),
              ),
              Row(
                children: [
                  InkWell(
                    onTap: () => _scaffoldKey.currentState?.openDrawer(),
                    borderRadius: BorderRadius.circular(24),
                    child: const CircleAvatar(
                      radius: 18,
                      backgroundImage: AssetImage('assets/icons/profile.png'),
                    ),
                  ),
                  const SizedBox(width: 10),
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search for',
            hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
            prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 22),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          style: GoogleFonts.poppins(fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    final tabs = [
      ('All', Icons.shopping_basket_outlined),
      ('Fresh', null),
      ('Deals', null),
      ('Unique', null),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final t in tabs)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedTab = t.$1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: _selectedTab == t.$1 ? Colors.white : Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: _selectedTab == t.$1
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (t.$2 != null) ...[
                          Icon(t.$2!, size: 18, color: Colors.black87),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          t.$1,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: _selectedTab == t.$1 ? FontWeight.w600 : FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryGrid() {
    final categories = [
      ('Vegetables & fruits', Icons.eco),
      ('Atta, rice, oil & dals', Icons.grain),
      ('Dairy, eggs & bread', Icons.breakfast_dining),
      ('Cold Drinks & Juices', Icons.local_drink),
      ('Biscuits & Munchies', Icons.cookie),
      ('Home Cleaning', Icons.cleaning_services),
      ('Personal Care', Icons.face_retouching_natural),
      ('View all categories', Icons.arrow_forward),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
        children: [
          for (int i = 0; i < categories.length; i++)
            _CategoryTile(
              label: categories[i].$1,
              icon: categories[i].$2,
              isViewAll: i == categories.length - 1,
            ),
        ],
      ),
    );
  }

  Widget _buildMorningEssentials() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Morning Essentials',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: Text(
                  'View all >',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _MorningProductCard(
                  label: 'Special',
                  icon: Icons.local_dining,
                ),
                _MorningProductCard(
                  label: 'Bread',
                  icon: Icons.breakfast_dining,
                ),
                _MorningProductCard(
                  label: 'ID Idly & Dosa Batter 1kg',
                  icon: Icons.egg,
                ),
                _MorningProductCard(
                  label: 'Milk',
                  icon: Icons.local_drink,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomFeeBar() {
    return Row(
        children: [
          Text(
            '₹0 delivery fee • ₹0 handling fee',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.black54,
            ),
          ),
          const Spacer(),
          Text(
            '1/',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.black45,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black38,
            ),
          ),
        ],
    );
  }

  Widget _buildCtaButton() {
    return Material(
        color: _yellowDark,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.phone_outlined, size: 20, color: Colors.black87),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 18, color: Colors.black87),
                const SizedBox(width: 8),
                Icon(Icons.local_shipping_outlined, size: 20, color: Colors.black87),
                const SizedBox(width: 10),
                Text(
                  'Call us to place your order',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.label,
    required this.icon,
    this.isViewAll = false,
  });
  final String label;
  final IconData icon;
  final bool isViewAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 32,
                  color: isViewAll ? Colors.grey[700] : const Color(0xFF4CAF50),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MorningProductCard extends StatelessWidget {
  const _MorningProductCard({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: Container(
        width: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Icon(icon, size: 48, color: Colors.grey[600]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 11, color: Colors.black87),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: SizedBox(
                width: double.infinity,
                child: Material(
                  color: const Color(0xFF4CAF50),
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(10),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Center(
                        child: Text(
                          'Add',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
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
