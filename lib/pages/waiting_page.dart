import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_State/Cart.dart';
import 'tracking_page.dart';

enum OrderCategoryType {
  food,
  groceries,
  pesticides,
  mixed, // When cart has multiple categories
}

class WaitingPage extends StatefulWidget {
  const WaitingPage({super.key});

  @override
  State<WaitingPage> createState() => _WaitingPageState();
}

class _WaitingPageState extends State<WaitingPage>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _sparkController;
  late AnimationController _handController;
  late AnimationController _magnifierController;
  
  OrderCategoryType? _categoryType;

  @override
  void initState() {
    super.initState();
    _determineCategory();
    _setupAnimations();
    
    // Navigate to tracking page after 10 seconds
    Timer(const Duration(seconds: 10), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const TrackingPage(),
          ),
        );
      }
    });
  }

  void _determineCategory() {
    final cart = CartService.instance;
    if (cart.items.isEmpty) {
      _categoryType = OrderCategoryType.food; // Default
      return;
    }

    // Count categories
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

    // Determine primary category
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

  void _setupAnimations() {
    _mainController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _sparkController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat();

    _handController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _magnifierController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _sparkController.dispose();
    _handController.dispose();
    _magnifierController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              
              // Title
              Text(
                'Preparing Your Order',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              
              const SizedBox(height: 60),
              
              // Animation based on category
              SizedBox(
                width: 300,
                height: 300,
                child: _buildCategoryAnimation(),
              ),
              
              const SizedBox(height: 40),
              
              // Status text
              Text(
                _getStatusText(),
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 60),
              
              // Loading indicator
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.redAccent),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryAnimation() {
    switch (_categoryType) {
      case OrderCategoryType.food:
        return _FoodAnimation(
          mainController: _mainController,
          sparkController: _sparkController,
        );
      case OrderCategoryType.groceries:
        return _GroceriesAnimation(
          handController: _handController,
        );
      case OrderCategoryType.pesticides:
        return _PesticidesAnimation(
          magnifierController: _magnifierController,
        );
      default:
        return _FoodAnimation(
          mainController: _mainController,
          sparkController: _sparkController,
        );
    }
  }

  String _getStatusText() {
    switch (_categoryType) {
      case OrderCategoryType.food:
        return 'Cooking your delicious meal...';
      case OrderCategoryType.groceries:
        return 'Packing your groceries...';
      case OrderCategoryType.pesticides:
        return 'Quality checking your order...';
      default:
        return 'Preparing your order...';
    }
  }
}

// 🍳 FOOD ANIMATION: Pan on stove with sizzle sparks
class _FoodAnimation extends StatelessWidget {
  final AnimationController mainController;
  final AnimationController sparkController;

  const _FoodAnimation({
    required this.mainController,
    required this.sparkController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([mainController, sparkController]),
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Stove base
            Container(
              width: 200,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
            ),
            
            // Pan
            Transform.translate(
              offset: Offset(0, -20),
              child: Container(
                width: 140,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange[200],
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            
            // Sizzle sparks 💥
            ...List.generate(12, (index) {
              final angle = (index * math.pi * 2) / 12;
              // Stagger spark timing
              final sparkDelay = (index % 3) * 0.1;
              final sparkValue = ((sparkController.value + sparkDelay) % 1.0);
              final distance = 50 + (sparkValue * 40);
              final opacity = (1 - sparkValue * 1.5).clamp(0.0, 1.0);
              final size = 4 + (sparkValue * 4);
              
              return Positioned(
                left: 150 + math.cos(angle) * distance,
                top: 150 + math.sin(angle) * distance,
                child: Opacity(
                  opacity: opacity,
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      color: Colors.orange[400],
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.9),
                          blurRadius: 6,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

// 🛒 GROCERIES ANIMATION: Hand picking items into bag
class _GroceriesAnimation extends StatelessWidget {
  final AnimationController handController;

  const _GroceriesAnimation({required this.handController});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: handController,
      builder: (context, child) {
        final handY = 50.0 + (handController.value * 80);
        final itemOpacity = handController.value < 0.5
            ? (handController.value * 2).clamp(0.0, 1.0)
            : (1 - (handController.value - 0.5) * 2).clamp(0.0, 1.0);
        
        return Stack(
          alignment: Alignment.center,
          children: [
            // Brown paper bag
            Positioned(
              bottom: 50,
              child: Container(
                width: 120,
                height: 160,
                decoration: BoxDecoration(
                  color: const Color(0xFF8B4513),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.brown.withOpacity(0.3),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Bag opening
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 30,
                        decoration: BoxDecoration(
                          color: const Color(0xFF654321),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    
                    // Items in bag (stacked)
                    if (handController.value > 0.6)
                      Positioned(
                        bottom: 20,
                        left: 20,
                        right: 20,
                        child: Opacity(
                          opacity: (handController.value - 0.6) * 2.5,
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.green[300],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            // Hand
            Positioned(
              left: 80,
              top: handY,
              child: Transform.rotate(
                angle: handController.value < 0.5
                    ? -0.2 * handController.value
                    : -0.1 + 0.2 * (handController.value - 0.5),
                child: Container(
                  width: 50,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFDBB3),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Fingers
                      Positioned(
                        top: 5,
                        left: 10,
                        child: Container(
                          width: 8,
                          height: 20,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFDBB3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 5,
                        right: 10,
                        child: Container(
                          width: 8,
                          height: 20,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFDBB3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Item being picked (apple/grocery item)
            Positioned(
              left: 100,
              top: handY + 30,
              child: Opacity(
                opacity: itemOpacity,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.red[400],
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3),
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.green[600],
                        shape: BoxShape.circle,
                      ),
                    ),
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

// 🔍 PESTICIDES ANIMATION: Magnifying glass quality check
class _PesticidesAnimation extends StatelessWidget {
  final AnimationController magnifierController;

  const _PesticidesAnimation({required this.magnifierController});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: magnifierController,
      builder: (context, child) {
        final magnifierX = 50.0 + (math.sin(magnifierController.value * math.pi * 2) * 100);
        final magnifierY = 100.0 + (math.cos(magnifierController.value * math.pi * 2) * 40);
        
        return Stack(
          alignment: Alignment.center,
          children: [
            // Bottle
            Positioned(
              bottom: 60,
              child: Container(
                width: 80,
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.green[700],
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Bottle label
                    Positioned(
                      top: 20,
                      left: 10,
                      right: 10,
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Text(
                            'PEST',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // Bottle cap
                    Positioned(
                      top: 0,
                      left: 20,
                      right: 20,
                      child: Container(
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Magnifying glass
            Positioned(
              left: magnifierX,
              top: magnifierY,
              child: Transform.rotate(
                angle: magnifierController.value * math.pi * 0.3,
                child: Stack(
                  children: [
                    // Glass lens
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.brown[700]!,
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.brown.withOpacity(0.3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blue[50]!.withOpacity(0.3),
                          border: Border.all(
                            color: Colors.blue[200]!,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    
                    // Handle
                    Positioned(
                      right: -15,
                      top: 20,
                      child: Transform.rotate(
                        angle: -0.3,
                        child: Container(
                          width: 8,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.brown[700],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    
                    // Quality check highlight
                    if (magnifierController.value > 0.3 && magnifierController.value < 0.7)
                      Positioned(
                        left: 5,
                        top: 5,
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.green[400]!,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            // "Quality Checking" text
            if (magnifierController.value > 0.4 && magnifierController.value < 0.6)
              Positioned(
                bottom: 220,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[400]!),
                  ),
                  child: Text(
                    'Quality Checking',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.green[800],
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

