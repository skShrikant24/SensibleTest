import 'package:http/http.dart' as http;

/// Base URL for GraBiTT API.
const String _baseUrl = 'https://grabitt.in';

/// Result of AddNewUser API call.
class AddNewUserResult {
  final bool success;
  final String? message;
  final String? rawResponse;

  const AddNewUserResult({
    required this.success,
    this.message,
    this.rawResponse,
  });
}

/// Global API service for user-related endpoints.
/// Use [UserApiService.addNewUser] from anywhere in the app.
class UserApiService {
  UserApiService._();

  static final UserApiService instance = UserApiService._();

  /// Registers a new user.
  /// [phoneno], [name], [email], [password], [dateOfBirth], [sex] are sent as query params.
  /// [lon] and [lan] are longitude and latitude (from location permission).
  /// API: GET /webservice.asmx/AddNewUser?phoneno=...&Name=...&Email=...&Password=...&DateOfBirth=...&Sex=...&lon=...&lan=...
  Future<AddNewUserResult> addNewUser({
    required String phoneno,
    required String name,
    required String email,
    required String password,
    required String dateOfBirth,
    required String sex,
    required String lon,
    required String lan,
  }) async {
    final uri = Uri.parse('$_baseUrl/webservice.asmx/AddNewUser').replace(
      queryParameters: <String, String>{
        'phoneno': phoneno,
        'Name': name,
        'Email': email,
        'Password': password,
        'DateOfBirth': dateOfBirth,
        'Sex': sex,
        'lon': lon,
        'lan': lan,
      },
    );

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final body = response.body.trim();
        // Handle common API response patterns (e.g. "success", "fail", or JSON)
        final success = body.toLowerCase() != 'fail' &&
            !body.toLowerCase().contains('"success":false') &&
            body.isNotEmpty;
        return AddNewUserResult(
          success: success,
          rawResponse: body,
          message: success ? 'Account created successfully' : body,
        );
      } else {
        return AddNewUserResult(
          success: false,
          message: 'Server error: ${response.statusCode}',
          rawResponse: response.body,
        );
      }
    } catch (e) {
      return AddNewUserResult(
        success: false,
        message: e.toString(),
        rawResponse: null,
      );
    }
  }
}
