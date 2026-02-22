import 'package:flutter/material.dart';

class AppConstants {
  static final String USER_NAME = "Hello";
  static final String APP_NAME = "GraBiTT";
  /// Indian Rupee symbol – use for all price displays (no dollar).
  static const String currencySymbol = '₹';
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

  // --- Tracking page & shared UI ---

  /// Primary text (headings, body)
  static const Color textPrimary = Color(0xFF212121);

  /// Secondary / muted text
  static const Color textSecondary = Color(0xFF616161);

  /// Road strip, progress track background
  static const Color road = Color(0xFFBDBDBD);

  /// Ribbon / progress highlight (warm gold)
  static const Color ribbon = Color(0xFFD97706);

  /// Ribbon light (gradient start)
  static const Color ribbonLight = Color(0xFFFCD34D);

  /// Rider / delivery icon and accents
  static const Color rider = Color(0xFF2563EB);

  /// Success state (delivered, success text)
  static const Color success = Color(0xFF16A34A);

  /// Success dark (headings on success screen)
  static const Color successDark = Color(0xFF166534);

  /// Light surface (map background, inputs)
  static const Color surfaceVariant = Color(0xFFF5F5F5);

  /// Progress bar track
  static const Color progressTrack = Color(0xFFE0E0E0);

  /// CTA / OTP button (attention)
  static const Color ctaAction = Color(0xFFFF5252);

  /// Package box brown
  static const Color boxBrown = Color(0xFF92400E);

  /// Box brown dark (shadow, lid)
  static const Color boxBrownDark = Color(0xFF78350F);

  /// Box ribbon accent
  static const Color boxRibbon = Color(0xFFF87171);

  /// Phase background – road (light gray tint)
  static const Color trackingPhaseRoad = Color(0xFFF5F5F5);

  /// Phase background – doorbell (warm tint)
  static const Color trackingPhaseDoorbell = Color(0xFFFEF3C7);

  /// Phase background – unboxing (success tint)
  static const Color trackingPhaseUnboxing = Color(0xFFD1FAE5);
}
