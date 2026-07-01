import 'package:GraBiTT/pages/login_page.dart';
import 'package:GraBiTT/services/auth_service.dart';
import 'package:flutter/material.dart';

class AuthGuard {
  static Future<bool> requireLogin(
    BuildContext context, {
    String message = 'Please login to continue.',
  }) async {
    final isLoggedIn = await AuthService.instance.isLoggedIn();
    if (isLoggedIn) return true;
    if (!context.mounted) return false;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
    return false;
  }
}
