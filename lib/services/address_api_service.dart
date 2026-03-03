import 'dart:convert';

import 'package:GraBiTT/models/address_model.dart';
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
    final response = await http.get(uri);
    final cleaned = _cleanResponse(response.body);
    return response.statusCode == 200 &&
        cleaned.isNotEmpty &&
        cleaned.toLowerCase() != 'fail';
  } catch (_) {
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
    return response.statusCode == 200 &&
        cleaned.isNotEmpty &&
        cleaned.toLowerCase() != 'fail';
  } catch (_) {
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
