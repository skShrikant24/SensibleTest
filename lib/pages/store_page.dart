import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:grabitt/app_State/cart.dart';
import 'package:grabitt/app_State/locale_provider.dart';
import 'package:grabitt/l10n/app_localizations.dart';
import 'package:grabitt/models/address_model.dart';
import 'package:grabitt/models/category.dart';
import 'package:grabitt/models/store_feed_model.dart';
import 'package:grabitt/models/vender.dart';
import 'package:grabitt/pages/address_management_page.dart';
import 'package:grabitt/pages/cart_page.dart';
import 'package:grabitt/pages/category_vendors_page.dart';
import 'package:grabitt/pages/components/header_pill.dart';
import 'package:grabitt/pages/login_page.dart';
import 'package:grabitt/services/address_api_service.dart';
import 'package:grabitt/services/auth_service.dart';
import 'package:grabitt/services/selected_address_storage.dart';
import 'package:grabitt/services/store_feed_service.dart';
import 'package:grabitt/utils/app_logger.dart';
import 'package:grabitt/utils/constants.dart';
import 'package:grabitt/utils/shared_classes.dart';
import 'package:grabitt/widgets/address_selector_sheet.dart';
import 'package:grabitt/widgets/home_banner_slider.dart';

class StorePage extends StatefulWidget {
  final ValueChanged<int> onSelectTab;
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
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  static const double _scrollThreshold = 10.0;
  double _lastScrollOffset = 0;
  bool _bottomBarHidden = false;
  static const double _bottomBarHeight = 100.0;

  // Location & Store Feed State
  StoreFeedResponse? _feedResponse;
  bool _loadingFeed = true;
  String _currentPincode = ''; // Resolved dynamically, no hardcoded Hunsur
  String _currentLat = '';
  String _currentLon = '';
  AddressModel? _selectedAddress;
  List<AddressModel> _userAddresses = [];
  String? _userId;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
    LocaleProvider.instance.addListener(_onLocaleChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initLocationAndFeed();
    });
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    if (query != _searchQuery) {
      setState(() => _searchQuery = query);
    }
  }

  Future<void> _initLocationAndFeed() async {
    setState(() => _loadingFeed = true);

    // Sync cart with server on startup / screen load
    CartService.instance.syncCartFromServer();

    try {
      // 1. Check saved address from local storage
      final saved = await SelectedAddressStorage.instance.load();

      // 2. Check logged-in user and fetch addresses
      final user = await AuthService.instance.getSavedUser();
      final uid =
          user?['ID']?.toString() ?? user?['UserID']?.toString() ?? '';
      _userId = uid.isNotEmpty ? uid : null;

      if (_userId != null) {
        _userAddresses = await getAddressByUser(_userId!);
      }

      AddressModel? activeAddress = saved;
      if (saved != null && _userAddresses.isNotEmpty) {
        try {
          activeAddress = _userAddresses.firstWhere(
            (a) => a.id == saved.id,
            orElse: () => saved,
          );
        } catch (_) {
          activeAddress = saved;
        }
      } else if (activeAddress == null && _userAddresses.isNotEmpty) {
        activeAddress = _userAddresses.first;
        await SelectedAddressStorage.instance.save(activeAddress);
      }

      if (activeAddress != null) {
        _selectedAddress = activeAddress;
        _currentPincode = activeAddress.pincode.trim();
        _currentLat = activeAddress.lan;
        _currentLon = activeAddress.lon;
        await _fetchFeed();
      } else {
        // No saved address: check if a pincode was previously selected
        final savedPincode =
            await SelectedAddressStorage.instance.loadPincode();
        if (savedPincode != null && savedPincode.isNotEmpty) {
          _selectedAddress = null;
          _currentPincode = savedPincode;
          _currentLat = '';
          _currentLon = '';
          await _fetchFeed();
        } else {
          // No saved address and no saved pincode: Attempt safe GPS auto-detection
          final pos = await _getGpsPosition();
          if (pos != null) {
            _currentLat = pos.latitude.toString();
            _currentLon = pos.longitude.toString();
            _currentPincode = '';
            _selectedAddress = null;
          }
          await _fetchFeed();

          // If location is STILL unknown (GPS off or permission denied):
          // Automatically prompt with Pincode Picker sheet so user is not stuck!
          if (_currentPincode.isEmpty && _currentLat.isEmpty && mounted) {
            _showPincodePickerSheet();
          }
        }
      }
    } catch (_) {
      await _fetchFeed();
    }
  }

  /// Safe, non-mutating GPS position fetcher across all Android (Android 8 to 15) and iOS versions.
  /// Returns Position if permission is granted and GPS is on, or null otherwise.
  Future<Position?> _getGpsPosition() async {
    try {
      // 1. Check and request location permission first
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        AppLogger.d('StorePage', 'Location permission denied: $permission');
        return null;
      }

      // 2. Permission granted! Check if GPS hardware is turned ON
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        AppLogger.d('StorePage', 'GPS hardware is turned off on device');
        return null;
      }

      // 3. Both permission and GPS are ON: Fetch coordinates with 5s timeout
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 5),
        ),
      );
    } catch (e) {
      AppLogger.w('StorePage', 'GPS position fetch skipped/failed: $e');
      return null;
    }
  }

  Future<void> _fetchFeed() async {
    if (!mounted) return;
    setState(() => _loadingFeed = true);

    // If neither pincode nor GPS coordinates are available, show location prompt
    if (_currentPincode.isEmpty && _currentLat.isEmpty) {
      setState(() {
        _feedResponse = StoreFeedResponse(
          status: 'NoLocation',
          isServiceable: false,
          city: '',
          pincode: '',
          message:
              'Please select your delivery location or pincode to check available stores near you.',
          categories: [],
          vendors: [],
          banners: [],
          pagination: FeedPagination(
            page: 1,
            pageSize: 50,
            totalCount: 0,
            hasMore: false,
          ),
        );
        _loadingFeed = false;
      });
      return;
    }

    final lang = LocaleProvider.instance.languageCode;
    final feed = await StoreFeedService.instance.getStoreFeed(
      pincode: _currentPincode,
      lat: _currentLat,
      lon: _currentLon,
      lang: lang,
      pageSize: 50,
    );

    if (!mounted) return;
    setState(() {
      _feedResponse = feed;
      if (_currentPincode.isEmpty && feed.pincode.isNotEmpty) {
        _currentPincode = feed.pincode;
      }
      _loadingFeed = false;
    });

    if (_selectedAddress == null && _currentPincode.isNotEmpty) {
      SelectedAddressStorage.instance.savePincode(_currentPincode);
    }

    if (feed.isServiceable && feed.banners.isNotEmpty) {
      _checkAndShowLocationBanners(feed.banners);
    }
  }

  bool _isBannerPopupShowing = false;
  static final Set<String> _shownBannerLocations = {};

  Future<void> _checkAndShowLocationBanners(List<HomeBannerModel> banners) async {
    if (_isBannerPopupShowing || banners.isEmpty || !mounted) return;

    final locationKey = _currentPincode.isNotEmpty
        ? _currentPincode
        : (_feedResponse?.city ?? 'loc');
    if (_shownBannerLocations.contains(locationKey)) return;

    _isBannerPopupShowing = true;
    _shownBannerLocations.add(locationKey);

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) {
      _isBannerPopupShowing = false;
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => HomeBannerPopup(
        banners: banners,
        onClose: () {
          _isBannerPopupShowing = false;
          if (mounted) Navigator.pop(context);
        },
      ),
    ).then((_) {
      _isBannerPopupShowing = false;
    });
  }

  void _onLocaleChanged() {
    if (!mounted) return;
    _fetchFeed();
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    final delta = offset - _lastScrollOffset;
    if (delta > _scrollThreshold) {
      _lastScrollOffset = offset;
      setState(() => _bottomBarHidden = true);
      widget.onScrollDirection?.call(true);
    } else if (delta < -_scrollThreshold) {
      _lastScrollOffset = offset;
      setState(() => _bottomBarHidden = false);
      widget.onScrollDirection?.call(false);
    }
  }

  @override
  void dispose() {
    LocaleProvider.instance.removeListener(_onLocaleChanged);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Location Selector & Cart Location Safety
  // ---------------------------------------------------------------------------

  /// Shows confirmation if cart contains items from a different store/location.
  /// If target location matches the cart items' vendor city/pincode or the vendor is present in targetVendors, returns true without prompting.
  Future<bool> _confirmLocationChangeIfCartNotEmpty({
    String? targetPincode,
    String? targetCity,
    AddressModel? targetAddress,
    List<Vendor>? targetVendors,
  }) async {
    final cartCount = CartService.instance.count;
    if (cartCount == 0) return true;

    final cartPin = CartService.instance.vendorPincode.trim();
    final cartC = CartService.instance.vendorCity.trim().toUpperCase();
    final cartVendorId = CartService.instance.vendorId.trim();

    final targetPin = (targetPincode ?? targetAddress?.pincode ?? '').trim();
    final targetC =
        (targetCity ?? targetAddress?.city ?? '').trim().toUpperCase();

    // Determine if target location matches the cart's vendor location
    bool isSameLocation = false;
    if (targetPin.isNotEmpty && cartPin.isNotEmpty && targetPin == cartPin) {
      isSameLocation = true;
    } else if (targetC.isNotEmpty && cartC.isNotEmpty && targetC == cartC) {
      isSameLocation = true;
    } else if (cartVendorId.isNotEmpty &&
        targetVendors != null &&
        targetVendors.any((v) => v.id.trim() == cartVendorId)) {
      isSameLocation = true;
    }

    if (isSameLocation) {
      // Same delivery zone or store is available in this zone: keep cart items intact!
      return true;
    }

    // Different city / delivery zone: Ask user for confirmation
    final vendorName = CartService.instance.vendorName;
    final displayName =
        vendorName.isNotEmpty ? vendorName : 'a restaurant/store';
    final currentLocName = cartC.isNotEmpty
        ? cartC
        : (cartPin.isNotEmpty ? 'Pincode $cartPin' : 'your current location');
    final targetLocName = targetPin.isNotEmpty
        ? 'Pincode $targetPin'
        : (targetC.isNotEmpty ? targetC : 'a new location');

    final bool? confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Change Delivery Location?',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        content: Text(
          'Your cart contains $cartCount item${cartCount > 1 ? "s" : ""} from $displayName ($currentLocName).\n\nChanging delivery location to $targetLocName will clear your current cart.',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: Colors.grey[700],
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: StoreProfileTheme.accentPink,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Clear Cart & Proceed',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await CartService.instance.clearCart(syncServer: true);
      if (!success) {
        if (mounted) {
          ToastMessage.error(
            context: context,
            msg:
                'Failed to clear cart on server. Please check your internet connection and try again.',
          );
        }
        return false;
      }
      return true;
    }
    return false;
  }

  Future<void> _openLocationSelector() async {
    if (_userId != null && _userId!.isNotEmpty && _userAddresses.isNotEmpty) {
      // Logged in with saved addresses: show saved addresses sheet
      final picked = await showModalBottomSheet<AddressModel>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => AddressSelectorSheet(
          addresses: _userAddresses,
          selected: _selectedAddress,
          userId: _userId!,
          onAddNew: () async {
            Navigator.pop(ctx);
            final result = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) => AddressFormPage(userId: _userId!),
              ),
            );
            if (result == true && mounted) {
              _userAddresses = await getAddressByUser(_userId!);
              if (_userAddresses.isNotEmpty) {
                final newest = _userAddresses.first;
                await _applyAddressSelection(newest);
              }
            }
          },
          onEdit: (addressToEdit) async {
            Navigator.pop(ctx);
            final result = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) => AddressFormPage(
                  userId: _userId!,
                  address: addressToEdit,
                ),
              ),
            );
            if (result == true && mounted) {
              _userAddresses = await getAddressByUser(_userId!);
              final updated = _userAddresses.firstWhere(
                (a) => a.id == addressToEdit.id,
                orElse: () => _userAddresses.first,
              );
              await _applyAddressSelection(updated);
            }
          },
          onManage: () async {
            Navigator.pop(ctx);
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const AddressManagementPage(),
              ),
            );
            if (mounted) {
              _userAddresses = await getAddressByUser(_userId!);
              final saved = await SelectedAddressStorage.instance.load();
              if (saved != null &&
                  _userAddresses.any((a) => a.id == saved.id)) {
                final match =
                    _userAddresses.firstWhere((a) => a.id == saved.id);
                await _applyAddressSelection(match);
              } else if (_userAddresses.isNotEmpty) {
                await _applyAddressSelection(_userAddresses.first);
              }
            }
          },
        ),
      );

      if (picked != null && mounted) {
        await _applyAddressSelection(picked);
      }
    } else {
      // Guest or logged-in user with no saved addresses: show Pincode picker bottom sheet
      await _showPincodePickerSheet();
    }
  }

  Future<void> _applyAddressSelection(AddressModel address) async {
    if (_selectedAddress?.id == address.id &&
        _currentPincode == address.pincode) {
      return;
    }

    final proceed = await _confirmLocationChangeIfCartNotEmpty(
      targetAddress: address,
      targetPincode: address.pincode,
      targetCity: address.city,
    );
    if (!proceed) return;

    await SelectedAddressStorage.instance.save(address);
    setState(() {
      _selectedAddress = address;
      _currentPincode =
          address.pincode.isNotEmpty ? address.pincode : '';
      _currentLat = address.lan;
      _currentLon = address.lon;
    });
    await _fetchFeed();
  }

  Future<void> _showPincodePickerSheet() async {
    final pinController = TextEditingController(text: _currentPincode);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Select Delivery Location',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: StoreProfileTheme.accentPink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Detect your GPS location or enter 6-digit delivery pincode',
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 14),
            // 🎯 GPS Detect Location Button
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () async {
                Navigator.pop(ctx);
                final position = await _getGpsPosition();
                if (position == null) {
                  if (mounted) {
                    ToastMessage.warning(
                      context: context,
                      msg: 'Unable to detect GPS. Please enter pincode below.',
                    );
                  }
                  return;
                }

                final newLat = position.latitude.toString();
                final newLon = position.longitude.toString();
                final lang = LocaleProvider.instance.languageCode;
                final previewFeed =
                    await StoreFeedService.instance.getStoreFeed(
                  lat: newLat,
                  lon: newLon,
                  lang: lang,
                  pageSize: 50,
                );

                final proceed = await _confirmLocationChangeIfCartNotEmpty(
                  targetPincode: previewFeed.pincode,
                  targetCity: previewFeed.city,
                  targetVendors: previewFeed.vendors,
                );
                if (!proceed) return;

                await SelectedAddressStorage.instance.clear();
                if (previewFeed.pincode.isNotEmpty) {
                  await SelectedAddressStorage.instance
                      .savePincode(previewFeed.pincode);
                }

                if (mounted) {
                  setState(() {
                    _selectedAddress = null;
                    _currentLat = newLat;
                    _currentLon = newLon;
                    _currentPincode = previewFeed.pincode;
                  });
                  await _fetchFeed();
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: StoreProfileTheme.lightPink.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: StoreProfileTheme.accentPink.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.my_location,
                        size: 18, color: StoreProfileTheme.accentPink),
                    const SizedBox(width: 8),
                    Text(
                      'Use Current GPS Location',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: StoreProfileTheme.accentPink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                hintText: 'Enter 6-digit Pincode',
                counterText: '',
                prefixIcon: const Icon(Icons.pin_drop_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Popular Areas:',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  label: const Text('Hunsur (571105)'),
                  onPressed: () {
                    pinController.text = '571105';
                  },
                ),
                ActionChip(
                  label: const Text('Pune (411057)'),
                  onPressed: () {
                    pinController.text = '411057';
                  },
                ),
                ActionChip(
                  label: const Text('Mumbai (400001)'),
                  onPressed: () {
                    pinController.text = '400001';
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: StoreProfileTheme.accentPink,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      final val = pinController.text.trim();
                      if (val.length != 6) {
                        ToastMessage.warning(
                          context: ctx,
                          msg: 'Please enter a valid 6-digit pincode',
                        );
                        return;
                      }
                      if (_currentPincode == val && _selectedAddress == null) {
                        Navigator.pop(ctx);
                        return;
                      }
                      Navigator.pop(ctx);
                      final proceed =
                          await _confirmLocationChangeIfCartNotEmpty(
                        targetPincode: val,
                      );
                      if (!proceed) return;

                      await SelectedAddressStorage.instance.clear();
                      await SelectedAddressStorage.instance.savePincode(val);
                      setState(() {
                        _selectedAddress = null;
                        _currentPincode = val;
                        _currentLat = '';
                        _currentLon = '';
                      });
                      await _fetchFeed();
                    },
                    child: Text(
                      'Apply Location',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
            if (_userId == null) ...[
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    );
                  },
                  child: Text(
                    'Login to use saved addresses',
                    style: GoogleFonts.poppins(
                      color: StoreProfileTheme.accentPink,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ] else if (_userAddresses.isEmpty) ...[
              const SizedBox(height: 12),
              Center(
                child: TextButton.icon(
                  icon: const Icon(Icons.add_location_alt_outlined,
                      color: StoreProfileTheme.accentPink, size: 18),
                  label: Text(
                    'Add new delivery address',
                    style: GoogleFonts.poppins(
                      color: StoreProfileTheme.accentPink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final result = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddressFormPage(userId: _userId!),
                      ),
                    );
                    if (result == true && mounted) {
                      await _initLocationAndFeed();
                    }
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
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
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16)),
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

  // ---------------------------------------------------------------------------
  // Build Main Screen
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isServiceable = _feedResponse?.isServiceable ?? true;

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
                  // 🔝 Top Header Section (Location, Lang, Profile, Cart)
                  SliverToBoxAdapter(
                    child: _buildTopHeader(),
                  ),

                  // Loading State
                  if (_loadingFeed)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: _bottomBarHeight),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: StoreProfileTheme.accentPink,
                          ),
                        ),
                      ),
                    )
                  // 🚫 Unserviceable / Coming Soon State
                  else if (!isServiceable)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildUnserviceableWidget(),
                    )
                  // ✅ Serviceable State: Search, Categories, Stores
                  else ...[
                    // 🔍 Search Bar
                    SliverToBoxAdapter(
                      child: _buildSearchBar(),
                    ),

                    // 🏷️ Categories Section
                    SliverToBoxAdapter(
                      child: _buildVendorGrid(),
                    ),

                    const SliverToBoxAdapter(
                      child: SizedBox(height: 40),
                    ),
                  ],
                ],
              ),
            ),
            // Fixed bottom quick order button (only when serviceable)
            if (!_loadingFeed && isServiceable) _buildFixedActionButtons(),
          ],
        ),
      ),
    );
  }

  // 🔝 Top Header: Delivery info, Location Dropdown, Language, Icons
  Widget _buildTopHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // First Row: Delivery in mins & Language
          Consumer<LocaleProvider>(
            builder: (context, localeProvider, _) {
              final l10n = AppLocalizations.of(context)!;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.deliveryInMins,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.green[700],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showLanguageSheet(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            StoreProfileTheme.lightPink.withValues(alpha: 0.5),
                        border: Border.all(color: StoreProfileTheme.border),
                        borderRadius: BorderRadius.circular(6),
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
                          Icon(
                            Icons.arrow_drop_down,
                            size: 18,
                            color: Colors.grey[700],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 10),

          // Second Row: Location Selector & Action Icons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 📍 Location Dropdown Selector
              Expanded(
                child: GestureDetector(
                  onTap: _openLocationSelector,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: StoreProfileTheme.border.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 18,
                          color: StoreProfileTheme.accentPink,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _selectedAddress != null
                                    ? (_selectedAddress!.area.isNotEmpty
                                        ? _selectedAddress!.area
                                        : _selectedAddress!.city)
                                    : (_feedResponse?.city.isNotEmpty == true
                                        ? _feedResponse!.city
                                        : (_currentPincode.isNotEmpty
                                            ? 'Deliver to'
                                            : 'Select Location')),
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                _currentPincode.isNotEmpty
                                    ? _currentPincode
                                    : (_currentLat.isNotEmpty
                                        ? 'GPS Location'
                                        : 'Tap to choose area'),
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: Colors.black87,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Icons: Profile, Cart
              Row(
                children: [
                  HeaderPill(
                    icon: Icons.person_outline,
                    onTap: () => widget.onSelectTab(1),
                  ),
                  const SizedBox(width: 8),
                  AnimatedBuilder(
                    animation: CartService.instance,
                    builder: (context, _) {
                      return HeaderPill(
                        icon: Icons.shopping_cart_outlined,
                        badgeCount: CartService.instance.count,
                        shouldAnimate: CartService.instance.shouldAnimateCart,
                        onTap: () {
                          if (_currentPincode.isEmpty &&
                              _currentLat.isEmpty &&
                              _selectedAddress == null) {
                            ToastMessage.warning(
                              context: context,
                              msg: 'Please select delivery location first',
                            );
                            _openLocationSelector();
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CartPage(),
                            ),
                          );
                        },
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

  // 🚫 Unserviceable / Coming Soon Screen (Blocks Category & Store Display)
  Widget _buildUnserviceableWidget() {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final bottomInset = mediaQuery.padding.bottom;

    // Adaptive sizing for compact screens (e.g. Galaxy A7 2017, iPhone SE, etc.)
    final bool isCompact = screenHeight < 720;
    final double lottieHeight = isCompact ? 130.0 : 175.0;
    final double totalBottomPadding = _bottomBarHeight + bottomInset + 16.0;
    final bool hasNoLocation = _currentPincode.isEmpty && _currentLat.isEmpty;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        isCompact ? 12 : 24,
        24,
        totalBottomPadding,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: lottieHeight,
            child: Lottie.asset(
              'assets/animations/Delivery.json',
              repeat: true,
              errorBuilder: (_, __, ___) => Icon(
                Icons.location_off_rounded,
                size: isCompact ? 70 : 90,
                color: StoreProfileTheme.accentPink,
              ),
            ),
          ),
          SizedBox(height: isCompact ? 12 : 18),
          Text(
            hasNoLocation ? "Select Delivery Location" : "We're not here yet!",
            style: GoogleFonts.poppins(
              fontSize: isCompact ? 20 : 22,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isCompact ? 6 : 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              _feedResponse?.message.isNotEmpty == true
                  ? _feedResponse!.message
                  : (hasNoLocation
                      ? "Please select your delivery location or enter your pincode to check available stores near you."
                      : "GraBiTT is currently not delivering in $_currentPincode. We are expanding fast and coming soon to your area!"),
              style: GoogleFonts.poppins(
                fontSize: isCompact ? 13 : 14,
                color: Colors.grey[700],
                height: 1.35,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: isCompact ? 18 : 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.location_on_outlined,
                  color: Colors.white, size: 20),
              label: Text(
                hasNoLocation ? 'Select Location' : 'Change Location',
                style: GoogleFonts.poppins(
                  fontSize: isCompact ? 14 : 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: StoreProfileTheme.accentPink,
                padding: EdgeInsets.symmetric(vertical: isCompact ? 12 : 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              onPressed: _openLocationSelector,
            ),
          ),
          SizedBox(height: isCompact ? 10 : 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: Icon(
                hasNoLocation ? Icons.my_location : Icons.refresh,
                color: StoreProfileTheme.accentPink,
                size: 20,
              ),
              label: Text(
                hasNoLocation ? 'Detect My Location (GPS)' : 'Try Again',
                style: GoogleFonts.poppins(
                  fontSize: isCompact ? 13 : 14,
                  fontWeight: FontWeight.w600,
                  color: StoreProfileTheme.accentPink,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(
                    color: StoreProfileTheme.accentPink, width: 1.5),
                padding: EdgeInsets.symmetric(vertical: isCompact ? 12 : 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: hasNoLocation
                  ? () async {
                      final pos = await _getGpsPosition();
                      if (pos != null) {
                        _currentLat = pos.latitude.toString();
                        _currentLon = pos.longitude.toString();
                        _currentPincode = '';
                        _selectedAddress = null;
                      }
                      await _fetchFeed();
                    }
                  : _fetchFeed,
            ),
          ),
        ],
      ),
    );
  }

  // 🔍 Search Bar
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _searchController.clear();
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          style: GoogleFonts.poppins(fontSize: 14),
        ),
      ),
    );
  }

  // 🏷️ Categories Grid
  Widget _buildVendorGrid() {
    final allCategories = _feedResponse?.categories ?? [];
    final filteredCategories = _searchQuery.isEmpty
        ? allCategories
        : allCategories
            .where((c) => c.name.toLowerCase().contains(_searchQuery))
            .toList();

    if (filteredCategories.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                "No categories found for this area",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: filteredCategories.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.82,
        ),
        itemBuilder: (context, index) {
          final category = filteredCategories[index];

          return _CategoryGridTile(
            label: category.name,
            imageUrl: category.imageUrl,
            isSelected: false,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CategoryVendorsPage(
                    categoryName: category.name,
                    categoryId: category.id,
                    pincode: _currentPincode,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // 🚀 Fixed bottom action buttons
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
                Text(
                  "Prescription & Order Notice",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: StoreProfileTheme.accentPink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "GraB iTT! is a delivery service platform. We do not provide medical advice or diagnosis. All medicines are delivered based on valid prescriptions. Please consult with a qualified healthcare professional.",
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
                    child: const Text(
                      "OKAY",
                      style: TextStyle(color: Colors.white),
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

// 🏷️ Category grid tile
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
                  placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image_outlined),
                  ),
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

// Backward-compatible fallback functions
Future<List<Category>> fetchCategories([String lang = 'en']) async {
  try {
    final response = await http.get(
      Uri.parse('https://grabitt.in/webservice.asmx/GetCategory').replace(
        queryParameters: {'lang': lang},
      ),
    );

    if (response.statusCode == 200) {
      final jsonString = response.body.replaceAll(RegExp(r'<[^>]*>'), '');
      final List data = json.decode(jsonString);
      return data.map((e) => Category.fromJson(e)).toList();
    }
  } catch (_) {}
  return [];
}

Future<List<Vendor>> fetchVendorsByCategory(
  String category, [
  String lang = 'en',
]) async {
  try {
    final url =
        'https://grabitt.in/webservice.asmx/GetVendorsCategoryWiseImages?categoryid=${Uri.encodeComponent(category)}&lang=${Uri.encodeComponent(lang)}';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) return [];
    final cleaned = response.body.replaceAll(RegExp(r'<[^>]*>'), '').trim();
    if (cleaned.isEmpty ||
        cleaned.toLowerCase() == 'no data' ||
        cleaned.toLowerCase() == 'fail' ||
        cleaned == 'null') {
      return [];
    }
    dynamic decoded = json.decode(cleaned);
    if (decoded is List) {
      return decoded.map((e) => Vendor.fromJson(e)).toList();
    }
    if (decoded is Map) {
      return [Vendor.fromJson(Map<String, dynamic>.from(decoded))];
    }
    return [];
  } catch (_) {
    return [];
  }
}
