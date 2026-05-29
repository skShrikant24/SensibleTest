import 'package:GraBiTT/models/vender.dart';
import 'package:GraBiTT/pages/category_vendors_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:GraBiTT/app_State/locale_provider.dart';
import 'package:GraBiTT/l10n/app_localizations.dart';
import 'package:GraBiTT/pages/components/header_pill.dart';
import 'package:GraBiTT/pages/cart_page.dart';
import 'package:GraBiTT/pages/pick_deliver_order_page.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/category.dart';
import '../app_State/cart.dart';
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
  late Future<List<Category>> _categoriesFuture;
  late Future<List<Vendor>> _vendorsFuture;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  static const double _scrollThreshold = 10.0;
  double _lastScrollOffset = 0;

  /// When true, bottom nav is hidden (scrolled down) → buttons sit at very bottom.
  bool _bottomBarHidden = false;

  /// Approximate height of main_shell bottom bar (with padding) so buttons sit above it when visible.
  static const double _bottomBarHeight = 72;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    final lang = LocaleProvider.instance.languageCode;
    _categoriesFuture = fetchCategories(lang);
    LocaleProvider.instance.addListener(_onLocaleChanged);
  }

  void _onLocaleChanged() {
    if (!mounted) return;
    final lang = LocaleProvider.instance.languageCode;
    setState(() {
      _categoriesFuture = fetchCategories(lang);
    });
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
    LocaleProvider.instance.removeListener(_onLocaleChanged);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _showLanguageSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeProvider = context.read<LocaleProvider>();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: StoreProfileTheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.selectLanguage,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                title: Text(l10n.english),
                trailing: localeProvider.isEnglish
                    ? Icon(Icons.check, color: StoreProfileTheme.accentPink)
                    : null,
                onTap: () async {
                  await localeProvider.setEnglish();
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
              ListTile(
                title: Text(l10n.kannada),
                trailing: localeProvider.isKannada
                    ? Icon(Icons.check, color: StoreProfileTheme.accentPink)
                    : null,
                onTap: () async {
                  await localeProvider.setKannada();
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: StoreProfileTheme.background,
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
                    child: _buildVendorGrid(),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 50,
                    ),
                  ),
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
          Consumer<LocaleProvider>(
            builder: (context, localeProvider, _) {
              final l10n = AppLocalizations.of(context)!;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.deliveryInMins,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.green[700],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showLanguageSheet(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color:
                            StoreProfileTheme.lightPink.withValues(alpha: 0.5),
                        border: Border.all(color: StoreProfileTheme.border),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Text(
                            localeProvider.isKannada
                                ? l10n.kannada
                                : l10n.english,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_drop_down,
                              size: 18, color: Colors.grey[600]),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 12),

          // Second Row: Location & Icons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  // TODO: Open location selector
                },
                child: Row(
                  children: [
                    Text(
                      AppLocalizations.of(context)!.location,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios,
                        size: 12, color: Colors.grey),
                  ],
                ),
              ),

              // Icons: Profile, Cart, Notification
              Row(
                children: [
                  // Profile tab
                  HeaderPill(
                    icon: Icons.monetization_on,
                    text: '25',
                    onTap: () => widget.onSelectTab(1),
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
                  /*  HeaderPill(
                    icon: Icons.notifications_none_rounded,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NotificationsPage()),
                      );
                    },
                  ),*/
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
            hintText: AppLocalizations.of(context)!.searchForAnything,
            hintStyle: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          style: GoogleFonts.poppins(fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildVendorGrid() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: FutureBuilder<List<Category>>(
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
              title: AppLocalizations.of(context)!.pickAndDeliver,
              icon: Icons.local_shipping_outlined,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const PickDeliverOrderPage(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: _ActionButton(
              title: "Medicine, Grocery or\nPesticides prescription",
              icon: Icons.flash_on,
              onTap: () {
                _showQuickOrderDisclaimer(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showQuickOrderDisclaimer(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: StoreProfileTheme.accentPink.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    size: 40,
                    color: StoreProfileTheme.accentPink,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Disclaimer",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "GraB iTT! is a medicine delivery service platform. We do not provide medical advice, diagnosis, or treatment. All medicines are delivered based on valid prescriptions from licensed medical practitioners. Please consult with a qualified healthcare professional before using any medication. We are not responsible for any adverse effects or complications arising from the use of medicines ordered through our platform. Also, Pesticides for lawful use only. Follow label instructions. Keep away from children. GraB iTT! is not responsible for any misuse.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: StoreProfileTheme.accentPink,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () async {
                      Navigator.pop(context);
                      await _openQuickOrderWhatsApp(context);
                    },
                    child: Text(
                      "OKAY",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openQuickOrderWhatsApp(BuildContext context) async {
    const message =
        "Hi GraB iTT!, I want to place a Quick Order. I will share my prescription or grocery list.";
    final whatsappUri = Uri.parse(
      "https://wa.me/916360974868?text=${Uri.encodeComponent(message)}",
      // "https://wa.me/919764658896?text=${Uri.encodeComponent(message)}",
    );

    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      return;
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Unable to open WhatsApp right now.")),
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
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  memCacheWidth: 300,
                  maxWidthDiskCache: 400,
                  fadeInDuration: const Duration(milliseconds: 150),
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
                  errorWidget: (_, __, ___) {
                    return CachedNetworkImage(
                      imageUrl: _placeholder,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (context, url) {
                        return Container(
                          color: Colors.grey[200],
                        );
                      },
                      errorWidget: (_, __, ___) {
                        return Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.broken_image_outlined,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.visible,
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

Future<List<Category>> fetchCategories([String lang = 'en']) async {
  final response = await http.get(
    Uri.parse('https://grabitt.in/webservice.asmx/GetCategory').replace(
      queryParameters: {'lang': lang},
    ),
  );

  if (response.statusCode == 200) {
    final jsonString = response.body.replaceAll(RegExp(r'<[^>]*>'), '');
    final List data = json.decode(jsonString);
    return data.map((e) => Category.fromJson(e)).toList();
  } else {
    throw Exception('Failed to load categories');
  }
}

Future<List<Vendor>> fetchVendorsByCategory(String category,
    [String lang = 'en']) async {
  try {
    final url =
        'https://grabitt.in/webservice.asmx/GetVendorsCategoryWiseImages?categoryid=${Uri.encodeComponent(category)}&lang=${Uri.encodeComponent(lang)}';
    print("_________________________________");
    print("URL=> $url");
    print("_________________________________");
    final response = await http.get(Uri.parse(url));

    if (response.statusCode != 200) return [];

    /// Remove XML wrapper
    final cleaned = response.body.replaceAll(RegExp(r'<[^>]*>'), '').trim();
    print("______________-------------------___________________");
    print("VENDOR API RAW => $cleaned");
    print("______________-------------------___________________");

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
      rating: json['Rating'] != null
          ? double.tryParse(json['Rating'].toString())
          : null,
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
    return List.generate(
        4,
        (index) => Restaurant(
              id: 'rest_${index + 1}',
              name: 'Restaurant ${index + 1}',
              category: 'Restaurant',
              rating: 4.0 + (index * 0.2),
            ));
  } else if (categoryLower.contains('restaurant')) {
    return List.generate(
        4,
        (index) => Restaurant(
              id: 'rest_${index + 1}',
              name: 'Restaurant ${index + 1}',
              category: 'Restaurant',
              rating: 4.0 + (index * 0.2),
            ));
  } else if (categoryLower.contains('grocery')) {
    return List.generate(
        3,
        (index) => Restaurant(
              id: 'grocery_${index + 1}',
              name: 'Grocery Store ${index + 1}',
              category: 'Grocery',
              rating: 4.2 + (index * 0.1),
            ));
  } else if (categoryLower.contains('medical') ||
      categoryLower.contains('pharmacy')) {
    return List.generate(
        3,
        (index) => Restaurant(
              id: 'medical_${index + 1}',
              name: 'Medical Store ${index + 1}',
              category: 'Medical',
              rating: 4.5 + (index * 0.1),
            ));
  } else {
    // Default: return restaurants for any other category
    return List.generate(
        2,
        (index) => Restaurant(
              id: 'store_${index + 1}',
              name: '$category Store ${index + 1}',
              category: category,
              rating: 4.0,
            ));
  }
}
