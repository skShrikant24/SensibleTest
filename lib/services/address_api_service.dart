import 'dart:convert';

import 'package:grabitt/models/address_model.dart';
import 'package:grabitt/utils/app_logger.dart';
import 'package:http/http.dart' as http;

const String _tag = 'AddressApiService';
const String _baseUrl = 'https://grabitt.in';

/// Cleans XML-wrapped response and returns inner string (e.g. JSON array).
String _cleanResponse(String body) {
  return body.replaceAll(RegExp(r'<[^>]*>'), '').trim();
}

/// GET GetAddressByUser?UserID=string
/// Returns list of addresses; empty on error or "Fail"/empty.
Future<List<AddressModel>> getAddressByUser(String userID) async {
  if (userID.isEmpty) return [];
  try {
    final uri = Uri.parse('$_baseUrl/webservice.asmx/GetAddressByUser').replace(
      queryParameters: {'UserID': userID},
    );
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      AppLogger.w(_tag, 'getAddressByUser: HTTP ${response.statusCode}');
      return [];
    }
    final cleaned = _cleanResponse(response.body);
    if (cleaned.isEmpty || cleaned.toLowerCase() == 'fail') return [];
    final decoded = json.decode(cleaned);
    if (decoded is! List) {
      AppLogger.w(_tag, 'getAddressByUser: unexpected response type');
      return [];
    }
    return decoded
        .map((e) => AddressModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  } catch (e, st) {
    AppLogger.e(_tag, 'getAddressByUser: failed to fetch addresses', e, st);
    return [];
  }
}

/// GET AddAddress with all query params.
/// Returns true if response indicates success (not "Fail").
Future<bool> addAddress({
  required String userID,
  required String addressType,
  required String addressLine1,
  required String addressLine2,
  required String landmark,
  required String area,
  required String city,
  required String district,
  required String state,
  required String pincode,
  required String lon,
  required String lan,
}) async {
  if (userID.isEmpty) return false;
  try {
    final uri = Uri.parse('$_baseUrl/webservice.asmx/AddAddress').replace(
      queryParameters: {
        'UserID': userID,
        'AddressType': addressType,
        'AddressLine1': addressLine1,
        'AddressLine2': addressLine2,
        'Landmark': landmark,
        'Area': area,
        'City': city,
        'District': district,
        'State': state,
        'Pincode': pincode,
        'lon': lon,
        'lan': lan,
      },
    );

    final response = await http.get(uri);
    final cleaned = _cleanResponse(response.body);
    final success = response.statusCode == 200 &&
        cleaned.isNotEmpty &&
        cleaned.toLowerCase() != 'fail';
    if (!success) {
      AppLogger.w(_tag,
          'addAddress: failed — HTTP ${response.statusCode}, body: $cleaned');
    }
    return success;
  } catch (e, st) {
    AppLogger.e(_tag, 'addAddress failed', e, st);
    return false;
  }
}

/// GET UpdateAddress?ID=...&...
/// UpdateAddress does not use AddressLine2 in your spec; we send it anyway for consistency.
Future<bool> updateAddress({
  required String id,
  required String addressType,
  required String addressLine1,
  required String addressLine2,
  required String landmark,
  required String area,
  required String city,
  required String district,
  required String state,
  required String pincode,
  required String lon,
  required String lan,
}) async {
  if (id.isEmpty) return false;
  try {
    final uri = Uri.parse('$_baseUrl/webservice.asmx/UpdateAddress').replace(
      queryParameters: {
        'ID': id,
        'AddressType': addressType,
        'AddressLine1': addressLine1,
        'AddressLine2': addressLine2,
        'Landmark': landmark,
        'Area': area,
        'City': city,
        'District': district,
        'State': state,
        'Pincode': pincode,
        'lon': lon,
        'lan': lan,
      },
    );

    final response = await http.get(uri);
    final cleaned = _cleanResponse(response.body);
    final success = response.statusCode == 200 &&
        cleaned.isNotEmpty &&
        cleaned.toLowerCase() != 'fail';
    if (!success) {
      AppLogger.w(_tag,
          'updateAddress: failed — HTTP ${response.statusCode}, body: $cleaned');
    }
    return success;
  } catch (e, st) {
    AppLogger.e(_tag, 'updateAddress failed', e, st);
    return false;
  }
}

/// GET DeleteAddress?ID=string
Future<bool> deleteAddress(String id) async {
  if (id.isEmpty) return false;
  try {
    final uri = Uri.parse('$_baseUrl/webservice.asmx/DeleteAddress').replace(
      queryParameters: {'ID': id},
    );
    final response = await http.get(uri);
    final cleaned = _cleanResponse(response.body);
    final success = response.statusCode == 200 &&
        cleaned.isNotEmpty &&
        cleaned.toLowerCase() != 'fail';
    if (!success) {
      AppLogger.w(_tag,
          'deleteAddress: failed — HTTP ${response.statusCode}, body: $cleaned');
    }
    return success;
  } catch (e, st) {
    AppLogger.e(_tag, 'deleteAddress failed', e, st);
    return false;
  }
}

class OrderRadiusCheckResult {
  final bool allowed;
  final String rawResponse;
  final double? minDistanceKm;
  final double? currentDistanceMeters;

  const OrderRadiusCheckResult({
    required this.allowed,
    required this.rawResponse,
    this.minDistanceKm,
    this.currentDistanceMeters,
  });

  String get userMessage {
    if (allowed) return 'Address is serviceable';
    if (minDistanceKm == null || currentDistanceMeters == null) {
      return 'Delivery is not available for this address right now.';
    }
    final currentKm = currentDistanceMeters!;
    return 'Delivery not available: minimum distance is ${minDistanceKm!.toStringAsFixed(1)} km, your address is ${currentKm.toStringAsFixed(2)} km away.';
  }
}

/// GET CheckOrderRadius?AddressID=string
/// Success => "Success"
/// Failure => "RadiusIssue|minDistanceKm|currentDistanceMeters"
Future<OrderRadiusCheckResult> checkOrderRadius(
  String addressId,
  String userId,
) async {
  if (addressId.trim().isEmpty || userId.trim().isEmpty) {
    return const OrderRadiusCheckResult(
      allowed: false,
      rawResponse: 'Address id missing',
    );
  }
  try {
    final uri = Uri.parse('$_baseUrl/WebService.asmx/CheckOrderRadius').replace(
      queryParameters: {
        'AddressID': addressId,
        'UserID': userId,
      },
    );
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      AppLogger.w(_tag, 'checkOrderRadius: HTTP ${response.statusCode}');
      return const OrderRadiusCheckResult(
        allowed: false,
        rawResponse: 'HTTP error',
      );
    }
    final cleaned = _cleanResponse(response.body);

    if (cleaned.toLowerCase() == 'success') {
      return OrderRadiusCheckResult(allowed: true, rawResponse: cleaned);
    }
    if (cleaned.startsWith('RadiusIssue|')) {
      final parts = cleaned.split('|');
      final minDistanceKm =
          parts.length > 1 ? double.tryParse(parts[1].trim()) : null;
      final currentDistanceMeters =
          parts.length > 2 ? double.tryParse(parts[2].trim()) : null;
      // print(currentDistanceMeters);
      return OrderRadiusCheckResult(
        allowed: false,
        rawResponse: cleaned,
        minDistanceKm: minDistanceKm,
        currentDistanceMeters: currentDistanceMeters,
      );
    }
    AppLogger.w(_tag, 'checkOrderRadius: unexpected response: $cleaned');
    return OrderRadiusCheckResult(allowed: false, rawResponse: cleaned);
  } catch (e, st) {
    AppLogger.e(_tag, 'checkOrderRadius failed', e, st);
    return const OrderRadiusCheckResult(
      allowed: false,
      rawResponse: 'Network error',
    );
  }
}
