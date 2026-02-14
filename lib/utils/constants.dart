import 'package:flutter/material.dart';

class AppConstants {
  static final String USER_NAME = "Hello";
  static final String APP_NAME = "GraBiTT";
}

/// Light pink color theme for Store and Profile pages (soft, inviting).
class StoreProfileTheme {
  StoreProfileTheme._();

  /// Page background – very pale pink (#FDF2F8)
  static const Color background = Color(0xFFFDF2F8);

  /// Light pink – avatar, "All" button bg, selected chip, section headers
  static const Color lightPink = Color(0xFFFBCFE8);

  /// Accent / selected text – darker magenta
  static const Color accentPink = Color(0xFFBE185D);

  /// Gradient for Offers / action buttons: warm to pink
  static const LinearGradient buttonGradient = LinearGradient(
    colors: [Color(0xFFFDE68A), Color(0xFFFBCFE8)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  /// View Menu / secondary button gradient: light pink to deeper pink
  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [Color(0xFFFBCFE8), Color(0xFFF472B6)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  /// Cards and search bar surface
  static const Color surface = Colors.white;

  /// Border for chips and cards
  static const Color border = Color(0xFFF9A8D4);
}
