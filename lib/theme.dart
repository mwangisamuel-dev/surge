import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SurgeColors {
  // Backgrounds — deep navy, not pitch black
  static const background   = Color(0xFF0C0C14);
  static const surface      = Color(0xFF13131F);
  static const card         = Color(0xFF18182A);
  static const cardLight    = Color(0xFF1E1E32);

  // Primary — softer violet, more lavender
  static const violet       = Color(0xFF7C6EFA);
  static const violetLight  = Color(0xFFA99BFF);
  static const violetSoft   = Color(0xFF3D357A);

  // Secondary — warm mint instead of harsh cyan
  static const mint         = Color(0xFF4ECDC4);
  static const mintSoft     = Color(0xFF1A4744);
  static const mintLight    = Color(0xFF80E8E2);

  // Accent colors — soft pastel blocks like inspo
  static const peach        = Color(0xFFFF9E7E);
  static const peachSoft    = Color(0xFF3D2318);
  static const lemon        = Color(0xFFFFD166);
  static const lemonSoft    = Color(0xFF3D3010);
  static const sage         = Color(0xFF95C8B0);
  static const sageSoft     = Color(0xFF1A3028);
  static const lavender     = Color(0xFFB8A9FF);
  static const lavenderSoft = Color(0xFF2A2450);

  // Text
  static const textPrimary   = Color(0xFFF2F2FA);
  static const textSecondary = Color(0xFF9898B8);
  static const textMuted     = Color(0xFF55557A);
  static const textDim       = Color(0xFF353555);

  // Semantic
  static const success = Color(0xFF4ECDC4);
  static const error   = Color(0xFFFF6B8A);
  static const warning = Color(0xFFFFD166);

  // Borders
  static const border      = Color(0xFF1E1E32);
  static const borderLight = Color(0xFF28284A);

  // Gradients
  static const gradientViolet = LinearGradient(
    colors: [Color(0xFF7C6EFA), Color(0xFF4A3FBF)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const gradientMint = LinearGradient(
    colors: [Color(0xFF4ECDC4), Color(0xFF2A8F88)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const gradientWarm = LinearGradient(
    colors: [Color(0xFFFF9E7E), Color(0xFFFF6B8A)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const gradientCard = LinearGradient(
    colors: [Color(0xFF1E1E32), Color(0xFF13131F)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  // Hero gradient — violet to mint like inspo color blocks
  static const gradientHero = LinearGradient(
    colors: [Color(0xFF7C6EFA), Color(0xFF4ECDC4)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
}

class SurgeTheme {
  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: SurgeColors.background,
    colorScheme: const ColorScheme.dark(
      primary: SurgeColors.violet,
      secondary: SurgeColors.mint,
      surface: SurgeColors.surface,
      error: SurgeColors.error,
    ),
    textTheme: GoogleFonts.plusJakartaSansTextTheme().apply(
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
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: SurgeColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: SurgeColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: SurgeColors.violet, width: 1.5),
      ),
      hintStyle: const TextStyle(
        color: SurgeColors.textMuted, fontSize: 14),
    ),
    useMaterial3: true,
  );
}