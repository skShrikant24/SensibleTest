import 'dart:convert';

import 'package:grabitt/utils/api_helper.dart';
import 'package:grabitt/utils/app_logger.dart';
import 'package:grabitt/widgets/home_banner_slider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String _tag = 'HomeBannerService';
const String _baseUrl = 'https://grabitt.in';
const String _keyBannerLastSeen = 'home_banner_last_seen';

class HomeBannerService {
  HomeBannerService._();
  static final HomeBannerService instance = HomeBannerService._();

  /// Returns active banners if they haven't been shown today.
  /// Returns null if shown already today, empty, or on error.
  Future<List<HomeBannerModel>?> fetchIfDue() async {
    try {
      final today = DateTime.now().toIso8601String().split('T').first;
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString(_keyBannerLastSeen) == today) return null;

      final res = await http.get(
        Uri.parse('$_baseUrl/Webservice.asmx/GetHomeBanner'),
      );
      if (res.statusCode != 200) {
        AppLogger.w(_tag, 'fetchIfDue: HTTP ${res.statusCode}');
        return null;
      }

      final cleaned = res.body
          .replaceAll(RegExp(r'<\?xml.*?\?>'), '')
          .replaceAll(RegExp(r'<string[^>]*>'), '')
          .replaceAll('</string>', '')
          .trim();

      final json = jsonDecode(cleaned) as Map<String, dynamic>;
      if (json['status'] != 'Success') return null;

      final data = json['data'];
      if (data is! List || data.isEmpty) return null;

      final banners = <HomeBannerModel>[];
      for (final item in data) {
        if (item == null || item['IsActive'] != true) continue;
        final image = item['Image']?.toString() ?? '';
        if (image.isEmpty) continue;
        banners.add(HomeBannerModel(
          imageUrl: ApiHelper.buildUrl(image) ?? '',
          title: item['ImageTitle']?.toString(),
          description: item['ImageDescription']?.toString(),
        ));
      }

      return banners.isEmpty ? null : banners;
    } catch (e, st) {
      AppLogger.e(_tag, 'fetchIfDue failed', e, st);
      return null;
    }
  }

  Future<void> markSeenToday() async {
    final today = DateTime.now().toIso8601String().split('T').first;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBannerLastSeen, today);
  }
}