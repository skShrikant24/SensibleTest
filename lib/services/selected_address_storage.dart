import 'dart:convert';

import 'package:grabitt/models/address_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _keySelectedAddress = 'grabitt_selected_address';

/// Saves and loads the selected checkout address for future use.
class SelectedAddressStorage {
  SelectedAddressStorage._();
  static final SelectedAddressStorage instance = SelectedAddressStorage._();

  Future<void> save(AddressModel address) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keySelectedAddress, jsonEncode(address.toJson()));
    } catch (_) {}
  }

  Future<AddressModel?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_keySelectedAddress);
      if (raw == null || raw.isEmpty) return null;
      final map = jsonDecode(raw) as Map<String, dynamic>?;
      if (map == null) return null;
      return AddressModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keySelectedAddress);
    } catch (_) {}
  }
}
