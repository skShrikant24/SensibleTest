import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import '../utils/constants.dart';

class HomeBannerModel {
  final String imageUrl;
  final String? title;
  final String? description;

  const HomeBannerModel({
    required this.imageUrl,
    this.title,
    this.description,
  });
}

class HomeBannerPopup extends StatelessWidget {
  final List<HomeBannerModel> banners;
  final VoidCallback onClose;

  const HomeBannerPopup({
    super.key,
    required this.banners,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;

    // In landscape the screen is wide but short — cap card width so the
    // 16:9 image height stays tall enough to be visible, and the text
    // section has room below it.
    final cardWidth = isLandscape
        ? (size.height * 0.75).clamp(0.0, size.width - 48)
        : size.width - 48;

    final imageHeight = cardWidth * (9 / 16);

    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 40,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // ── Card ──────────────────────────────────────────────────────
            Container(
              width: cardWidth,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                // Sketch: transparent bold border
                border: Border.all(
                  color: Colors.black.withValues(alpha: 0.15),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Image section (top, rounded top corners) ─────────
                    SizedBox(
                      width: cardWidth,
                      height: imageHeight,
                      child: banners.length == 1
                          ? _BannerImage(banner: banners.first)
                          : CarouselSlider.builder(
                              itemCount: banners.length,
                              itemBuilder: (_, index, __) =>
                                  _BannerImage(banner: banners[index]),
                              options: CarouselOptions(
                                viewportFraction: 1,
                                height: imageHeight,
                                autoPlay: true,
                                autoPlayInterval: const Duration(seconds: 4),
                                enlargeCenterPage: false,
                                scrollPhysics:
                                    const BouncingScrollPhysics(),
                              ),
                            ),
                    ),

                    // ── Divider line (sketch: flat line between image and text) ──
                    Container(
                      height: 1.5,
                      color: Colors.black.withValues(alpha: 0.12),
                    ),

                    // ── Text section (below divider, white background) ────
                    _BannerText(banners: banners),
                  ],
                ),
              ),
            ),

            // ── Close button ──────────────────────────────────────────────
            Positioned(
              top: -14,
              right: -14,
              child: Material(
                color: Colors.white,
                shape: const CircleBorder(),
                elevation: 4,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onClose,
                  child: const SizedBox(
                    height: 44,
                    width: 44,
                    child: Icon(
                      Icons.close,
                      size: 22,
                      color: Colors.black87,
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

/// Pure image — fills the fixed-height box with cover.
/// No text, no overlay. Admin can upload any landscape image.
class _BannerImage extends StatelessWidget {
  final HomeBannerModel banner;

  const _BannerImage({required this.banner});

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: banner.imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      memCacheWidth: 1080,
      maxWidthDiskCache: 1080,
      fadeInDuration: const Duration(milliseconds: 200),
      placeholder: (_, __) => const ColoredBox(
        color: Color(0xFFEEEEEE),
        child: Center(
          child: CircularProgressIndicator(
            color: StoreProfileTheme.accentPink,
          ),
        ),
      ),
      errorWidget: (_, __, ___) => const ColoredBox(
        color: Color(0xFFEEEEEE),
        child: Center(
          child: Icon(
            Icons.broken_image_outlined,
            size: 48,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}

/// Text section below the divider — left aligned, expandable on long text.
class _BannerText extends StatefulWidget {
  final List<HomeBannerModel> banners;

  const _BannerText({required this.banners});

  @override
  State<_BannerText> createState() => _BannerTextState();
}

class _BannerTextState extends State<_BannerText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final banner = widget.banners.first;
    final hasTitle = (banner.title ?? '').trim().isNotEmpty;
    final hasDescription = (banner.description ?? '').trim().isNotEmpty;

    if (!hasTitle && !hasDescription) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasTitle)
            Text(
              banner.title!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.left,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          if (hasTitle && hasDescription) const SizedBox(height: 4),
          if (hasDescription) ...[
            Text(
              banner.description!,
              maxLines: _expanded ? 10 : 2,
              overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
            // Show "View more / View less" only when text is long enough
            // to overflow 2 lines. LayoutBuilder detects the actual overflow.
            LayoutBuilder(
              builder: (context, constraints) {
                final span = TextSpan(
                  text: banner.description!,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                );
                final tp = TextPainter(
                  text: span,
                  maxLines: 2,
                  textDirection: TextDirection.ltr,
                )..layout(maxWidth: constraints.maxWidth);

                final isOverflowing = tp.didExceedMaxLines;
                if (!isOverflowing) return const SizedBox.shrink();

                return GestureDetector(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _expanded ? 'View less' : 'View more',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: StoreProfileTheme.accentPink,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}