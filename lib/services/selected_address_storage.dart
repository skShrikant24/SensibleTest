import 'dart:convert';

import 'package:grabitt/models/address_model.dart';
import 'package:grabitt/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _tag = 'SelectedAddressStorage';
const String _keySelectedAddress = 'grabitt_selected_address';
const String _keySelectedPincode = 'grabitt_selected_pincode';

/// Saves and loads the selected checkout address for future use.
class SelectedAddressStorage {
  SelectedAddressStorage._();
  static final SelectedAddressStorage instance = SelectedAddressStorage._();

  Future<void> save(AddressModel address) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keySelectedAddress, jsonEncode(address.toJson()));
      await clearPincode();
    } catch (e, st) {
      AppLogger.e(_tag, 'save: failed to persist selected address', e, st);
    }
  }

  Future<AddressModel?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_keySelectedAddress);
      if (raw == null || raw.isEmpty) return null;
      final map = jsonDecode(raw) as Map<String, dynamic>?;
      if (map == null) return null;
      return AddressModel.fromJson(map);
    } catch (e, st) {
      AppLogger.e(_tag, 'load: failed to read selected address', e, st);
      return null;
    }
  }

  Future<void> savePincode(String pincode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keySelectedPincode, pincode.trim());
    } catch (e, st) {
      AppLogger.e(_tag, 'savePincode failed', e, st);
    }
  }

  Future<String?> loadPincode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final p = prefs.getString(_keySelectedPincode);
      if (p != null && p.trim().isNotEmpty) return p.trim();
    } catch (_) {}
    return null;
  }

  Future<void> clearPincode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keySelectedPincode);
    } catch (_) {}
  }

  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keySelectedAddress);
      await prefs.remove(_keySelectedPincode);
    } catch (e, st) {
      AppLogger.e(_tag, 'clear: failed to remove selected address', e, st);
    }
  }
}
