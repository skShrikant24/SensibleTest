import 'dart:convert';
import 'package:grabitt/models/store_feed_model.dart';
import 'package:grabitt/utils/app_logger.dart';
import 'package:http/http.dart' as http;

const String _tag = 'StoreFeedService';
const String _baseUrl = 'https://grabitt.in';

class StoreFeedService {
  StoreFeedService._();
  static final StoreFeedService instance = StoreFeedService._();

  /// Fetches the location-based store feed (categories, vendors, banners, serviceability).
  Future<StoreFeedResponse> getStoreFeed({
    String pincode = '',
    String lat = '',
    String lon = '',
    String lang = 'en',
    String categoryId = '',
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final queryParams = <String, String>{
        'pincode': pincode.trim(),
        'lat': lat.trim(),
        'lon': lon.trim(),
        'lang': lang.trim().isEmpty ? 'en' : lang.trim(),
        'category_id': categoryId.trim(),
        'page': page.toString(),
        'pageSize': pageSize.toString(),
      };

      final uri = Uri.parse('$_baseUrl/webservice.asmx/GetStoreFeedByLocation')
          .replace(queryParameters: queryParams);

      AppLogger.d(_tag, 'Fetching store feed: $uri');

      final response = await http.get(uri);

      if (response.statusCode != 200) {
        AppLogger.w(
          _tag,
          'getStoreFeed: HTTP ${response.statusCode} - ${response.body}',
        );
        return StoreFeedResponse.unserviceable(
          pincode: pincode,
          message: 'Unable to connect to server. Please try again.',
        );
      }

      final rawBody = response.body.trim();
      final cleaned = rawBody.replaceAll(RegExp(r'<[^>]*>'), '').trim();

      if (cleaned.isEmpty || cleaned.toLowerCase() == 'fail') {
        AppLogger.w(_tag, 'getStoreFeed: empty or fail response');
        return StoreFeedResponse.unserviceable(
          pincode: pincode,
          message: 'Delivery not available in this area right now.',
        );
      }

      final dynamic decoded = jsonDecode(cleaned);
      if (decoded is! Map<String, dynamic>) {
        AppLogger.w(_tag, 'getStoreFeed: unexpected JSON root type');
        return StoreFeedResponse.unserviceable(pincode: pincode);
      }

      return StoreFeedResponse.fromJson(decoded);
    } catch (e, st) {
      AppLogger.e(_tag, 'getStoreFeed exception', e, st);
      return StoreFeedResponse.unserviceable(
        pincode: pincode,
        message: 'Could not load store feed. Please check your connection.',
      );
    }
  }
}
