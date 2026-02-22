import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

import '../app_State/Cart.dart';
import '../utils/constants.dart';
import 'tracking_page.dart';

enum OrderCategoryType {
  food,
  groceries,
  pesticides,
  mixed,
}

class WaitingPage extends StatefulWidget {
  const WaitingPage({super.key});

  @override
  State<WaitingPage> createState() => _WaitingPageState();
}

class _WaitingPageState extends State<WaitingPage> {
  OrderCategoryType? _categoryType;
  Timer? _navTimer;

  @override
  void initState() {
    super.initState();
    _determineCategory();
    _navTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const TrackingPage()),
        );
      }
    });
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    super.dispose();
  }

  void _determineCategory() {
    final cart = CartService.instance;
    if (cart.items.isEmpty) {
      _categoryType = OrderCategoryType.mixed;
      return;
    }

    int foodCount = 0;
    int groceryCount = 0;
    int pesticideCount = 0;

    for (var item in cart.items) {
      final categoryName = item.product.categoryName.toLowerCase();
      if (categoryName.contains('food') ||
          categoryName.contains('restaurant') ||
          categoryName.contains('meal')) {
        foodCount += item.quantity;
      } else if (categoryName.contains('grocery') ||
          categoryName.contains('groc')) {
        groceryCount += item.quantity;
      } else if (categoryName.contains('pesticide') ||
          categoryName.contains('agri') ||
          categoryName.contains('agriculture') ||
          categoryName.contains('farm')) {
        pesticideCount += item.quantity;
      }
    }

    if (foodCount > groceryCount && foodCount > pesticideCount) {
      _categoryType = OrderCategoryType.food;
    } else if (groceryCount > foodCount && groceryCount > pesticideCount) {
      _categoryType = OrderCategoryType.groceries;
    } else if (pesticideCount > foodCount && pesticideCount > groceryCount) {
      _categoryType = OrderCategoryType.pesticides;
    } else {
      _categoryType = OrderCategoryType.mixed;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StoreProfileTheme.background,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              // Title
              Text(
                'Placing your order',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: StoreProfileTheme.accentPink,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Please wait while we confirm your order',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: StoreProfileTheme.accentPink.withValues(alpha: 0.8),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              // Lottie animation
              SizedBox(
                width: 280,
                height: 280,
                child: Lottie.asset(
                  'assets/animations/OrderCart.json',
                  fit: BoxFit.contain,
                  repeat: true,
                  animate: true,
                ),
              ),
              const SizedBox(height: 32),
              // Status text
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _getStatusText(),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: StoreProfileTheme.accentPink.withValues(alpha: 0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 48),
              // Loading indicator
              SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    StoreProfileTheme.accentPink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getStatusText() {
    switch (_categoryType) {
      case OrderCategoryType.food:
        return 'Preparing your delicious meal...';
      case OrderCategoryType.groceries:
        return 'Packing your groceries with care...';
      case OrderCategoryType.pesticides:
        return 'Quality checking your items...';
      default:
        return 'We\'re preparing your order...';
    }
  }
}
