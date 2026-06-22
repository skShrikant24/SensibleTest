import 'dart:convert';
import 'package:grabitt/utils/app_logger.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String _tag = 'AuthService';
const String _baseUrl = 'https://grabitt.in';
const String _keyUser = 'grabitt_logged_in_user';
const String _keyIsLoggedIn = 'grabitt_is_logged_in';

class LoginResult {
  final bool success;
  final String? message;

  const LoginResult({
    required this.success,
    this.message,
  });
}

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
        AppLogger.w(_tag, 'getUserByPhone: HTTP ${response.statusCode}');
        return const GetUserByPhoneResult(found: false);
      }
      final raw = response.body.trim();
      final cleaned = raw.replaceAll(RegExp(r'<[^>]*>'), '').trim();
      if (cleaned.isEmpty || cleaned.toLowerCase() == 'fail') {
        return const GetUserByPhoneResult(found: false);
      }
      final user = json.decode(cleaned) as Map<String, dynamic>?;
      return GetUserByPhoneResult(found: true, user: user);
    } catch (e, st) {
      AppLogger.e(_tag, 'getUserByPhone failed', e, st);
      return const GetUserByPhoneResult(found: false);
    }
  }

  /// GET /webservice.asmx/SendOtp?mobileNumber=string&generatedOtp=string
  /// [generatedOtp] is the OTP we generate; server sends it via SMS.
  Future<SendOtpResult> sendOtp(
      String mobileNumber, String generatedOtp) async {
    final uri = Uri.parse('$_baseUrl/webservice.asmx/SendOtp').replace(
      queryParameters: {
        'mobileNumber': mobileNumber,
        'generatedOtp': generatedOtp,
      },
    );
    try {
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        AppLogger.w(_tag, 'sendOtp: HTTP ${response.statusCode}');
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
      } catch (e, st) {
        AppLogger.e(_tag, 'sendOtp: failed to parse JSON response', e, st);
        return SendOtpResult(success: false, message: cleaned);
      }
    } catch (e, st) {
      AppLogger.e(_tag, 'sendOtp failed', e, st);
      return SendOtpResult(success: false, message: e.toString());
    }
  }

  /// GET /Webservice.asmx/UserLogin?phoneno=string&Password=string
  Future<LoginResult> userLogin({
    required String phoneno,
    required String password,
  }) async {
    final uri = Uri.parse('$_baseUrl/Webservice.asmx/UserLogin').replace(
      queryParameters: {
        'phoneno': phoneno,
        'Password': password,
      },
    );

    try {
      final response = await http.get(uri);

      if (response.statusCode != 200) {
        AppLogger.w(_tag, 'userLogin: HTTP ${response.statusCode}');
        return const LoginResult(success: false, message: 'Server error');
      }

      final raw = response.body.trim();
      final cleaned = raw.replaceAll(RegExp(r'<[^>]*>'), '').trim();

      if (cleaned.isEmpty) {
        AppLogger.w(_tag, 'userLogin: empty response body');
        return const LoginResult(
            success: false, message: 'Something went wrong');
      }

      final map = json.decode(cleaned) as Map<String, dynamic>;

      final status = map['Status']?.toString() ?? '';
      final message = map['Message']?.toString() ?? '';

      return LoginResult(
        success: status.toLowerCase() == 'success',
        message: message,
      );
    } catch (e, st) {
      AppLogger.e(_tag, 'userLogin failed', e, st);
      return LoginResult(success: false, message: e.toString());
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
    } catch (e, st) {
      AppLogger.e(_tag, 'getSavedUser: failed to decode stored user', e, st);
      return null;
    }
  }

  /// Whether the user is considered logged in (has saved session).
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_keyIsLoggedIn) == true;
    final userData = prefs.getString(_keyUser);
    return isLoggedIn && userData != null && userData.isNotEmpty;
  }

  /// Clear saved user and logout.
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUser);
    await prefs.setBool(_keyIsLoggedIn, false);
  }
}
