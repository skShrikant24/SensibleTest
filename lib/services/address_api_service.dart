import 'dart:convert';

import 'package:grabitt/models/address_model.dart';
import 'package:http/http.dart' as http;

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
    if (response.statusCode != 200) return [];
    final cleaned = _cleanResponse(response.body);
    // print("--------adress----GetAddressByUser--");
    // print(cleaned);
    if (cleaned.isEmpty || cleaned.toLowerCase() == 'fail') return [];
    final decoded = json.decode(cleaned);
    if (decoded is! List) return [];
    return decoded
        .map((e) => AddressModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  } catch (_) {
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
    // print('\n========== ADD ADDRESS ==========');
    // print('REQUEST URL: ${uri.toString()}');

    final response = await http.get(uri);
    // print('STATUS CODE: ${response.statusCode}');
    // print('HEADERS: ${response.headers}');
    // print('RAW RESPONSE: ${response.body}');
    final cleaned = _cleanResponse(response.body);
    // print('CLEANED RESPONSE: $cleaned');
    // print(
    //     'SUCCESS: ${response.statusCode == 200 && cleaned.isNotEmpty && cleaned.toLowerCase() != 'fail'}');
    // print('================================\n');
    return response.statusCode == 200 &&
        cleaned.isNotEmpty &&
        cleaned.toLowerCase() != 'fail';
  } catch (_) {
    // print('\n========== ADD ADDRESS ERROR ==========');
    // print('ERROR: $e');
    // print('STACKTRACE: $s');
    // print('=======================================\n');
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
    // print('\n========== UPDATE ADDRESS ==========');
    // print('REQUEST URL: ${uri.toString()}');
    final response = await http.get(uri);
    // print('STATUS CODE: ${response.statusCode}');
    // print('HEADERS: ${response.headers}');
    // print('RAW RESPONSE: ${response.body}');
    final cleaned = _cleanResponse(response.body);
    // print('CLEANED RESPONSE: $cleaned');
    // print(
    //     'SUCCESS: ${response.statusCode == 200 && cleaned.isNotEmpty && cleaned.toLowerCase() != 'fail'}');
    // print('===================================\n');
    return response.statusCode == 200 &&
        cleaned.isNotEmpty &&
        cleaned.toLowerCase() != 'fail';
  } catch (_) {
    // print('\n========== UPDATE ADDRESS ERROR ==========');
    // print('ERROR: $e');
    // print('STACKTRACE: $s');
    // print('==========================================\n');
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
    return response.statusCode == 200 &&
        cleaned.isNotEmpty &&
        cleaned.toLowerCase() != 'fail';
  } catch (_) {
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
    // print("Check Radius URL => $uri");
    final response = await http.get(uri);
    // print("Check Radius Status => ${response.statusCode}");
    // print("Check Radius Raw => ${response.body}");
    if (response.statusCode != 200) {
      return const OrderRadiusCheckResult(
        allowed: false,
        rawResponse: 'HTTP error',
      );
    }
    final cleaned = _cleanResponse(response.body);
    // print(
    //     "----WebService.asmx/CheckOrderRadius--AddressID----$addressId--UserID----$userId");
    // print(cleaned);
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
    return OrderRadiusCheckResult(allowed: false, rawResponse: cleaned);
  } catch (e) {
    // print("Check Radius Error => $e");
    return const OrderRadiusCheckResult(
      allowed: false,
      rawResponse: 'Network error',
    );
  }
}
