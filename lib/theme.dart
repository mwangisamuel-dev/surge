import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SurgeColors {
  // Backgrounds — deeper, richer, less harsh
  static const background    = Color(0xFF08080F);
  static const surface       = Color(0xFF101018);
  static const card          = Color(0xFF161622);
  static const cardElevated  = Color(0xFF1C1C2A);

  // Accents — slightly muted, easier on eyes
  static const violet        = Color(0xFF6C4EFF);
  static const violetLight   = Color(0xFF8B6FFF);
  static const violetDim     = Color(0xFF3D2E99);
  static const cyan          = Color(0xFF00D4B4);
  static const cyanDim       = Color(0xFF009E87);

  // Text — softer contrast
  static const textPrimary   = Color(0xFFE8E8F0);
  static const textSecondary = Color(0xFF9898B0);
  static const textMuted     = Color(0xFF4A4A65);

  // Semantic — toned down
  static const success       = Color(0xFF1EA553);
  static const error         = Color(0xFFE03E5C);
  static const warning       = Color(0xFFE8993A);

  // Borders — barely visible
  static const border        = Color(0xFF1E1E30);
  static const borderLight   = Color(0xFF252538);

  // Gradients
  static const gradientViolet = LinearGradient(
    colors: [Color(0xFF6C4EFF), Color(0xFF3D2E99)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const gradientCyan = LinearGradient(
    colors: [Color(0xFF00D4B4), Color(0xFF007A68)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const gradientDark = LinearGradient(
    colors: [Color(0xFF1A1A28), Color(0xFF101018)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const gradientCard = LinearGradient(
    colors: [Color(0xFF1C1C2A), Color(0xFF161622)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static LinearGradient glow(Color c) => LinearGradient(
    colors: [c.withOpacity(0.18), c.withOpacity(0.02)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
}

class SurgeTheme {
  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: SurgeColors.background,
    colorScheme: const ColorScheme.dark(
      primary: SurgeColors.violet,
      secondary: SurgeColors.cyan,
      surface: SurgeColors.surface,
      error: SurgeColors.error,
    ),
    textTheme: GoogleFonts.dmSansTextTheme().apply(
      bodyColor: SurgeColors.textPrimary,
      displayColor: SurgeColors.textPrimary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: SurgeColors.background,
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: SurgeColors.textPrimary),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: SurgeColors.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: SurgeColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: SurgeColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: SurgeColors.violet, width: 1.5),
      ),
      hintStyle: const TextStyle(
        color: SurgeColors.textMuted, fontSize: 14),
    ),
    useMaterial3: true,
  );
}