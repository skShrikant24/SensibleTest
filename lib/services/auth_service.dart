import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String _baseUrl = 'https://grabitt.in';
const String _keyUser = 'grabitt_logged_in_user';
const String _keyIsLoggedIn = 'grabitt_is_logged_in';

/// Result of GetUserByPhone. [user] is null when response is "Fail".
class GetUserByPhoneResult {
  final bool found;
  final Map<String, dynamic>? user;

  const GetUserByPhoneResult({required this.found, this.user});
}

/// Result of SendOtp. [otp] may be present in response for debugging.
class SendOtpResult {
  final bool success;
  final String? message;
  final String? otp;

  const SendOtpResult({required this.success, this.message, this.otp});
}

/// Auth API + local login state (SharedPreferences).
class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  /// GET /webservice.asmx/GetUserByPhone?phoneno=string
  /// Response: XML-wrapped JSON or "Fail".
  Future<GetUserByPhoneResult> getUserByPhone(String phoneno) async {
    final uri = Uri.parse('$_baseUrl/webservice.asmx/GetUserByPhone').replace(
      queryParameters: {'phoneno': phoneno},
    );
    try {
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        return const GetUserByPhoneResult(found: false);
      }
      final raw = response.body.trim();
      final cleaned = raw.replaceAll(RegExp(r'<[^>]*>'), '').trim();
      if (cleaned.isEmpty || cleaned.toLowerCase() == 'fail') {
        return const GetUserByPhoneResult(found: false);
      }
      final user = json.decode(cleaned) as Map<String, dynamic>?;
      return GetUserByPhoneResult(found: true, user: user);
    } catch (_) {
      return const GetUserByPhoneResult(found: false);
    }
  }

  /// GET /webservice.asmx/SendOtp?mobileNumber=string&generatedOtp=string
  /// [generatedOtp] is the OTP we generate; server sends it via SMS.
  Future<SendOtpResult> sendOtp(String mobileNumber, String generatedOtp) async {
    final uri = Uri.parse('$_baseUrl/webservice.asmx/SendOtp').replace(
      queryParameters: {
        'mobileNumber': mobileNumber,
        'generatedOtp': generatedOtp,
      },
    );
    try {
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        return SendOtpResult(success: false, message: 'Server error');
      }
      final raw = response.body.trim();
      final cleaned = raw.replaceAll(RegExp(r'<[^>]*>'), '').trim();
      if (cleaned.isEmpty || cleaned.toLowerCase() == 'fail') {
        return const SendOtpResult(success: false, message: 'Fail');
      }
      try {
        final map = json.decode(cleaned) as Map<String, dynamic>?;
        final status = map?['status']?.toString() ?? '';
        final msg = map?['message']?.toString();
        final otp = map?['otp']?.toString();
        return SendOtpResult(
          success: status.toLowerCase() == 'success',
          message: msg,
          otp: otp,
        );
      } catch (_) {
        return SendOtpResult(success: false, message: cleaned);
      }
    } catch (e) {
      return SendOtpResult(success: false, message: e.toString());
    }
  }

  /// Save logged-in user and set isLoggedIn to true.
  Future<void> saveLoginUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUser, json.encode(user));
    await prefs.setBool(_keyIsLoggedIn, true);
  }

  /// Get saved user map; null if not logged in or no user.
  Future<Map<String, dynamic>?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_keyIsLoggedIn) != true) return null;
    final jsonStr = prefs.getString(_keyUser);
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      return json.decode(jsonStr) as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  /// Whether the user is considered logged in (has saved session).
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) == true;
  }

  /// Clear saved user and logout.
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUser);
    await prefs.setBool(_keyIsLoggedIn, false);
  }
}
