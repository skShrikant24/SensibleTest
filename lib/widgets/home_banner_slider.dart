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
    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 40,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.75,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: banners.length == 1
                    ? _BannerItem(
                        banner: banners.first,
                      )
                    : CarouselSlider.builder(
                        itemCount: banners.length,
                        itemBuilder: (_, index, __) {
                          return _BannerItem(
                            banner: banners[index],
                          );
                        },
                        options: CarouselOptions(
                          viewportFraction: 1,
                          autoPlay: true,
                          autoPlayInterval: const Duration(seconds: 4),
                          enlargeCenterPage: false,
                        ),
                      ),
              ),
            ),
            Positioned(
              top: -12,
              right: -12,
              child: Material(
                color: Colors.white,
                shape: const CircleBorder(),
                elevation: 2,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onClose,
                  child: const SizedBox(
                    height: 48,
                    width: 48,
                    child: Icon(
                      Icons.close,
                      size: 28,
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

class _BannerItem extends StatelessWidget {
  final HomeBannerModel banner;

  const _BannerItem({
    required this.banner,
  });

  @override
  Widget build(BuildContext context) {
    final hasTitle = (banner.title ?? '').trim().isNotEmpty;

    final hasDescription = (banner.description ?? '').trim().isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 320,
          width: double.infinity,
          child: CachedNetworkImage(
            imageUrl: banner.imageUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            memCacheWidth: 1080,
            maxWidthDiskCache: 1080,
            fadeInDuration: const Duration(milliseconds: 150),
            placeholder: (_, __) {
              return const SizedBox(
                height: 300,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            },
            errorWidget: (_, __, ___) {
              return const SizedBox.shrink();
            },
          ),
        ),
        if (hasTitle || hasDescription)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(
              16,
              12,
              16,
              16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasTitle)
                  Text(
                    banner.title!,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: StoreProfileTheme.textPrimary,
                    ),
                  ),
                if (hasTitle && hasDescription) const SizedBox(height: 6),
                if (hasDescription)
                  Text(
                    banner.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: StoreProfileTheme.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
