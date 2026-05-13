import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceService {
  DeviceService._();
  static final DeviceService instance = DeviceService._();

  static const String _deviceKey = "app_device_id";

  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();

    final savedId = prefs.getString(_deviceKey);
    if (savedId != null && savedId.isNotEmpty) {
      return savedId;
    }

    String deviceId = "";

    try {
      if (Platform.isAndroid) {
        final info = await _deviceInfo.androidInfo;
        deviceId = info.id;
      } 
      else if (Platform.isIOS) {
        final info = await _deviceInfo.iosInfo;
        deviceId = info.identifierForVendor ?? "";
      }

      if (deviceId.isEmpty) {
        deviceId = const Uuid().v4();
      }
    } catch (_) {
      deviceId = const Uuid().v4();
    }

    await prefs.setString(_deviceKey, deviceId);
    return deviceId;
  }
}