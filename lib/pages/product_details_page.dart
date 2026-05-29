import 'dart:math' as math;
import 'package:GraBiTT/l10n/app_localizations.dart';
import 'package:GraBiTT/utils/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../app_State/cart.dart';
import '../services/sound_service.dart';
import 'cart_page.dart';

class ProductDetailsPage extends StatefulWidget {
  final Product product;

  const ProductDetailsPage({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage>
    with TickerProviderStateMixin {
  final GlobalKey _imageKey = GlobalKey();
  final GlobalKey _cartIconKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  late AnimationController _flyController;
  late AnimationController _quoteController;
  late Animation<Offset> _flyAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  bool _showQuote = false;

  @override
  void initState() {
    super.initState();
    _flyController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _quoteController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Paper plane curve animation
    _flyAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(1, 1),
    ).animate(CurvedAnimation(
      parent: _flyController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.3).animate(
      CurvedAnimation(
        parent: _flyController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: math.pi * 2).animate(
      CurvedAnimation(
        parent: _flyController,
        curve: Curves.easeInOut,
      ),
    );

    _flyController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _removeOverlay();
      }
    });
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _flyController.dispose();
    _quoteController.dispose();
    // _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) {
      setState(() {
        _showQuote = false;
      });
    }
  }

  Offset _getCartIconPosition() {
    final RenderBox? renderBox =
        _cartIconKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return Offset.zero;
    final Offset position = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;
    return Offset(
      position.dx + size.width / 2,
      position.dy + size.height / 2,
    );
  }

  Offset _getImagePosition() {
    final RenderBox? renderBox =
        _imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return Offset.zero;

    final Offset position = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;
    return Offset(
      position.dx + size.width / 2,
      position.dy + size.height / 2,
    );
  }

  void _startPaperPlaneAnimation() async {
    // Wait for layout so both image and cart icon positions are available
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;

    final Offset startPos = _getImagePosition();
    final Offset endPos = _getCartIconPosition();

    _flyController.reset();
    _quoteController.reset();

    if (startPos == Offset.zero) {
      CartService.instance.addItem(widget.product);
      CartService.instance.triggerCartAnimation();
      return;
    }

    final Size screenSize = MediaQuery.of(context).size;
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final Offset fallbackEnd =
        Offset(screenSize.width - 36, statusBarHeight + 28);
    final Offset finalEndPos =
        (endPos.dx <= 0 || endPos.dy <= 0) ? fallbackEnd : endPos;

    setState(() {
      _showQuote = true;
    });

    _overlayEntry = OverlayEntry(
      builder: (context) => _PaperPlaneOverlay(
        startPos: startPos,
        endPos: finalEndPos,
        productImage: widget.product.allImages.first,
        flyAnimation: _flyAnimation,
        scaleAnimation: _scaleAnimation,
        rotationAnimation: _rotationAnimation,
        showQuote: _showQuote,
        quoteController: _quoteController,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    SoundService.instance.playWhoosh();
    _quoteController.forward();
    _flyController.forward().then((_) {
      if (mounted) {
        CartService.instance.addItem(widget.product);
        CartService.instance.triggerCartAnimation();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StoreProfileTheme.background,
      // 🛒 Bottom Add to Cart
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: StoreProfileTheme.accentPink,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: _startPaperPlaneAnimation,
              child: Text(
                AppLocalizations.of(context)!.addToCart,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // 🔙 AppBar
          SliverAppBar(
            backgroundColor: StoreProfileTheme.background,
            elevation: 0,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.pinkAccent),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              AppLocalizations.of(context)!.productDetails,
              style: const TextStyle(
                color: StoreProfileTheme.accentPink,
                fontWeight: FontWeight.w600,
              ),
            ),
            actions: [
              // 🛒 Cart Icon with Badge (key on IconButton so fly-to-cart ends at icon)
              AnimatedBuilder(
                animation: CartService.instance,
                builder: (context, _) {
                  return Stack(
                    children: [
                      IconButton(
                        key: _cartIconKey,
                        icon: const Icon(Icons.shopping_cart_outlined,
                            color: Colors.pinkAccent),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CartPage()),
                          );
                        },
                      ),
                      if (CartService.instance.count > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: IgnorePointer(
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                '${CartService.instance.count}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ),

          SliverToBoxAdapter(
            child: SizedBox(
              height: 300,
              child: (widget.product.allImages.isNotEmpty)
                  ? PageView(
                      children: widget.product.allImages
                          .asMap()
                          .entries
                          .map(
                            (entry) => CachedNetworkImage(
                              imageUrl: entry.value,
                              key: entry.key == 0 ? _imageKey : null,
                              fit: BoxFit.contain,
                              memCacheWidth: 700,
                              maxWidthDiskCache: 900,
                              fadeInDuration: const Duration(milliseconds: 150),
                              placeholder: (context, url) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              },
                              errorWidget: (_, __, ___) => _placeholder(),
                            ),
                          )
                          .toList(),
                    )
                  : _placeholder(),
            ),
          ),

          // 📦 Product Info
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category
                  Text(
                    widget.product.categoryName,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Name
                  Text(
                    widget.product.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Price Row
                  Row(
                    children: [
                      Text(
                        "${AppConstants.currencySymbol}${widget.product.discountPrice}",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "${AppConstants.currencySymbol}${widget.product.originalPrice}",
                        style: const TextStyle(
                          fontSize: 15,
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "${widget.product.discountPercent}% OFF",
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  Text(
                    AppLocalizations.of(context)!.productDetails,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${widget.product.description}",
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: double.infinity,
      color: StoreProfileTheme.lightPink.withValues(alpha: .25),
      child: Center(
        child: Icon(
          Icons.image_not_supported,
          size: 60,
          color: StoreProfileTheme.accentPink,
        ),
      ),
    );
  }
}

class _PaperPlaneOverlay extends StatelessWidget {
  final Offset startPos;
  final Offset endPos;
  final String productImage;
  final Animation<Offset> flyAnimation;
  final Animation<double> scaleAnimation;
  final Animation<double> rotationAnimation;
  final bool showQuote;
  final AnimationController quoteController;

  const _PaperPlaneOverlay({
    required this.startPos,
    required this.endPos,
    required this.productImage,
    required this.flyAnimation,
    required this.scaleAnimation,
    required this.rotationAnimation,
    required this.showQuote,
    required this.quoteController,
  });

  Offset _getCurvedPosition(double t) {
    // Paper plane curve: quadratic bezier curve
    final double x = startPos.dx + (endPos.dx - startPos.dx) * t;
    // Create a curve that goes up then down (like a paper plane)
    final double curveHeight = 100.0;
    final double y = startPos.dy +
        (endPos.dy - startPos.dy) * t -
        curveHeight * math.sin(t * math.pi);
    return Offset(x, y);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation:
          Listenable.merge([flyAnimation, scaleAnimation, rotationAnimation]),
      builder: (context, child) {
        final double t = flyAnimation.value.dx;
        final Offset currentPos = _getCurvedPosition(t);
        double scale = scaleAnimation.value;
        final double rotation = rotationAnimation.value;

        // Fade out and shrink into cart in last 25% so no small image stays visible
        final double endOpacity =
            t <= 0.75 ? 1.0 : ((1.0 - (t - 0.75) / 0.25).clamp(0.0, 1.0));
        if (t > 0.8) {
          scale = scale * ((1.0 - (t - 0.8) / 0.2).clamp(0.0, 1.0));
        }

        return IgnorePointer(
          child: Stack(
            children: [
              // Flying product image (hidden by opacity/scale at end so it ends at cart cleanly)
              if (endOpacity > 0.01 && scale > 0.01)
                Positioned(
                  left: currentPos.dx - 50 * scale,
                  top: currentPos.dy - 50 * scale,
                  child: Opacity(
                    opacity: endOpacity,
                    child: Transform.rotate(
                      angle: rotation * 0.5,
                      child: Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: CachedNetworkImage(
                            imageUrl: productImage,
                            fit: BoxFit.cover,
                            memCacheWidth: 250,
                            maxWidthDiskCache: 350,
                            fadeInDuration: const Duration(milliseconds: 100),
                            placeholder: (context, url) {
                              return Container(
                                color: Colors.grey[200],
                                child: const Center(
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              );
                            },
                            errorWidget: (context, url, error) {
                              return Container(
                                color: Colors.grey[300],
                                child: const Icon(Icons.image),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // Quote: "Fast as a flight."
              // if (showQuote && t < 0.8)
              //   Positioned(
              //     left: currentPos.dx - 60,
              //     top: currentPos.dy - 80,
              //     child: FadeTransition(
              //       opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
              //         CurvedAnimation(
              //           parent: quoteController,
              //           curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
              //         ),
              //       ),
              //       child: Container(
              //         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              //         decoration: BoxDecoration(
              //           color: Colors.black87,
              //           borderRadius: BorderRadius.circular(8),
              //         ),
              //         child: Text(
              //           '"Fast as a flight."',
              //           style: GoogleFonts.poppins(
              //             color: Colors.white,
              //             fontSize: 12,
              //             fontWeight: FontWeight.w500,
              //           ),
              //         ),
              //       ),
              //     ),
              //   ),
            ],
          ),
        );
      },
    );
  }
}
