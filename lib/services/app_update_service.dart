import 'dart:convert';
import 'dart:io';

import 'package:grabitt/utils/app_logger.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _tag = 'AppUpdateService';
const String _baseUrl = 'https://grabitt.in';
const String _keySkippedVersion = 'skipped_version';

class AppUpdateInfo {
  final String latestVersion;
  final bool forceUpdate;
  final String marketUri;
  final String webUri;

  const AppUpdateInfo({
    required this.latestVersion,
    required this.forceUpdate,
    required this.marketUri,
    required this.webUri,
  });
}

class AppUpdateService {
  AppUpdateService._();
  static final AppUpdateService instance = AppUpdateService._();

  /// Returns [AppUpdateInfo] if an update is available and not skipped.
  /// Returns null if app is up-to-date, already skipped, or on error.
  Future<AppUpdateInfo?> checkForUpdate() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final currentBuild = int.tryParse(info.buildNumber) ?? 0;

      final res = await http.get(
        Uri.parse('$_baseUrl/Webservice.asmx/GetCustomerAppVersion'),
      );
      if (res.statusCode != 200) {
        AppLogger.w(_tag, 'checkForUpdate: HTTP ${res.statusCode}');
        return null;
      }

      final cleaned = _cleanXml(res.body);
      final jsonData = jsonDecode(cleaned) as Map<String, dynamic>;
      final data = jsonData['data'];
      if (data == null) return null;

      final platformData =
          (Platform.isIOS ? data['ios'] : data['android']) as Map?;
      if (platformData == null) return null;

      final latestVersion = platformData['latest_version']?.toString() ?? '';
      final forceUpdate = platformData['force_update'] == true;
      final updateAvailable = platformData['update_available'] == true;
      final serverBuild =
          int.tryParse(platformData['build']?.toString() ?? '0') ?? 0;

      if (!updateAvailable || serverBuild <= currentBuild) return null;

      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString(_keySkippedVersion) == latestVersion) return null;

      final marketUri = Platform.isAndroid
          ? (platformData['market_uri']?.toString().isNotEmpty == true
              ? platformData['market_uri'].toString()
              : 'market://details?id=com.infisoft.grabit')
          : '';

      final webUri = Platform.isAndroid
          ? (platformData['web_uri']?.toString().isNotEmpty == true
              ? platformData['web_uri'].toString()
              : 'https://play.google.com/store/apps/details?id=com.infisoft.grabit')
          : (platformData['app_store_url']?.toString().isNotEmpty == true
              ? platformData['app_store_url'].toString()
              : 'https://apps.apple.com/app/idYOUR_APP_ID');

      return AppUpdateInfo(
        latestVersion: latestVersion,
        forceUpdate: forceUpdate,
        marketUri: marketUri,
        webUri: webUri,
      );
    } catch (e, st) {
      AppLogger.e(_tag, 'checkForUpdate failed', e, st);
      return null;
    }
  }

  Future<void> markSkipped(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySkippedVersion, version);
  }
}

String _cleanXml(String body) => body
    .replaceAll(RegExp(r'<\?xml.*?\?>'), '')
    .replaceAll(RegExp(r'<string[^>]*>'), '')
    .replaceAll('</string>', '')
    .trim();