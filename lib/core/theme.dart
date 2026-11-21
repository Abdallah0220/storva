import 'package:flutter/material.dart';

/// Central brand theme. Change the colors here to re-skin the whole store.
///
/// Current skin: "Atelier" - light, minimal, fashion-lookbook inspired.
/// Off-white canvas, ink-black text, thin type, pill-shaped controls.
/// The dark cinematic hero uses the noir palette below.
class AppTheme {
  AppTheme._();

  // Light lookbook palette.
  static const Color primary = Color(0xFF111111); // ink
  static const Color accent = Color(0xFF111111); // monochrome accents
  static const Color background = Color(0xFFF4F2EC); // warm off-white
  static const Color surface = Color(0xFFFDFCFA);
  static const Color textDark = Color(0xFF111111);
  static const Color textMuted = Color(0xFF8B887E);
  static const Color danger = Color(0xFFC0392B);
  static const Color success = Color(0xFF1E7F4F);
  static const Color warning = Color(0xFFB7791F);
  static const Color border = Color(0xFFDDDACF);
  static const Color dash = Color(0xFFB9B5A8); // dashed-circle strokes

  // Noir (dark cinematic) palette, used by the hero section.
  static const Color noirBg = Color(0xFF0B0B0E);
  static const Color noirGlowWarm = Color(0xFFFF5A2E);
  static const Color noirGlowCool = Color(0xFF4D7CFE);

  static const BorderRadius pillRadius = BorderRadius.all(Radius.circular(999));

  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: accent,
        surface: surface,
      ),
      textTheme: base.textTheme.apply(
        fontFamily: 'Poppins',
        bodyColor: textDark,
        displayColor: textDark,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: background,
        centerTitle: true,
        iconTheme: IconThemeData(color: textDark),
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          color: textDark,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: 2.0,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
          shape: const RoundedRectangleBorder(borderRadius: pillRadius),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary),
          shape: const RoundedRectangleBorder(borderRadius: pillRadius),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: pillRadius,
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: pillRadius,
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: pillRadius,
          borderSide: const BorderSide(color: primary, width: 1.4),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: const RoundedRectangleBorder(borderRadius: pillRadius),
        side: const BorderSide(color: border),
        backgroundColor: surface,
        selectedColor: primary,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: primary,
        contentTextStyle: TextStyle(fontFamily: 'Poppins', color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: pillRadius),
      ),
    );
  }

  /// Standard light card. Flat, hairline border, generous radius.
  static BoxDecoration get card => BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: border),
  );

  /// Eyebrow label style used above headings (thin, wide tracking).
  static const TextStyle eyebrow = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 2.4,
    color: textMuted,
  );

  /// Large thin display heading.
  static const TextStyle displayThin = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.5,
    height: 1.1,
    color: textDark,
  );
}
