import 'package:grabitt/models/category.dart';
import 'package:grabitt/models/vender.dart';
import 'package:grabitt/utils/api_helper.dart';
import 'package:grabitt/widgets/home_banner_slider.dart';

class FeedPagination {
  final int page;
  final int pageSize;
  final int totalCount;
  final bool hasMore;

  const FeedPagination({
    this.page = 1,
    this.pageSize = 10,
    this.totalCount = 0,
    this.hasMore = false,
  });

  factory FeedPagination.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const FeedPagination();
    return FeedPagination(
      page: int.tryParse(json['page']?.toString() ?? '1') ?? 1,
      pageSize: int.tryParse(json['pageSize']?.toString() ?? '10') ?? 10,
      totalCount: int.tryParse(json['totalCount']?.toString() ?? '0') ?? 0,
      hasMore: json['hasMore'] == true,
    );
  }
}

class StoreFeedResponse {
  final String status;
  final bool isServiceable;
  final String city;
  final String pincode;
  final String message;
  final List<Category> categories;
  final List<Vendor> vendors;
  final List<HomeBannerModel> banners;
  final FeedPagination pagination;

  const StoreFeedResponse({
    required this.status,
    required this.isServiceable,
    required this.city,
    required this.pincode,
    required this.message,
    required this.categories,
    required this.vendors,
    required this.banners,
    required this.pagination,
  });

  factory StoreFeedResponse.fromJson(Map<String, dynamic> json) {
    final status = json['status']?.toString() ?? '';
    final isServiceable = json['is_serviceable'] == true;
    final city = json['city']?.toString() ?? '';
    final pincode = json['pincode']?.toString() ?? '';
    final message = json['message']?.toString() ?? '';

    // Categories
    final rawCategories = json['categories'];
    final List<Category> categories = [];
    if (rawCategories is List) {
      for (final item in rawCategories) {
        if (item is Map<String, dynamic>) {
          categories.add(Category.fromJson(item));
        }
      }
    }

    // Vendors
    final rawVendors = json['vendors'];
    final List<Vendor> vendors = [];
    if (rawVendors is List) {
      for (final item in rawVendors) {
        if (item is Map<String, dynamic>) {
          vendors.add(Vendor.fromJson(item));
        }
      }
    }

    // Banners
    final rawBanners = json['banners'];
    final List<HomeBannerModel> banners = [];
    if (rawBanners is List) {
      for (final item in rawBanners) {
        if (item is Map<String, dynamic>) {
          final img = item['Image']?.toString() ?? '';
          if (img.isNotEmpty) {
            banners.add(
              HomeBannerModel(
                imageUrl: ApiHelper.buildUrl(img) ?? img,
                title: item['ImageTitle']?.toString(),
                description: item['ImageDescription']?.toString(),
              ),
            );
          }
        }
      }
    }

    // Pagination
    final pagination = FeedPagination.fromJson(
      json['pagination'] as Map<String, dynamic>?,
    );

    return StoreFeedResponse(
      status: status,
      isServiceable: isServiceable,
      city: city,
      pincode: pincode,
      message: message,
      categories: categories,
      vendors: vendors,
      banners: banners,
      pagination: pagination,
    );
  }

  factory StoreFeedResponse.unserviceable({
    required String pincode,
    String city = '',
    String message =
        'Sorry, we are not delivering in this area yet! We are coming soon to your area.',
  }) {
    return StoreFeedResponse(
      status: 'Success',
      isServiceable: false,
      city: city,
      pincode: pincode,
      message: message,
      categories: const [],
      vendors: const [],
      banners: const [],
      pagination: const FeedPagination(),
    );
  }
}
