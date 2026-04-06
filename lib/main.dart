import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'timer_app.dart';

void main() {
  runApp(const NCAFTimerApp());
}

class NCAFTimerApp extends StatelessWidget {
  const NCAFTimerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: const Color(0xFF406E51),
      onPrimary: const Color(0xFFFEFCF1),
      primaryContainer: const Color(0xFFC4E8D0),
      onPrimaryContainer: const Color(0xFF002112),
      secondary: const Color(0xFF9C5000),
      onSecondary: const Color(0xFFFEFCF1),
      secondaryContainer: const Color(0xFFFFDCC5),
      onSecondaryContainer: const Color(0xFF331500),
      tertiary: const Color(0xFF834AAE),
      onTertiary: const Color(0xFFFEFCF1),
      tertiaryContainer: const Color(0xFFEFD6FF),
      onTertiaryContainer: const Color(0xFF2B0054),
      error: const Color(0xFFBA1A1A),
      onError: const Color(0xFFFFFFFF),
      errorContainer: const Color(0xFFFFDAD6),
      onErrorContainer: const Color(0xFF410002),
      surface: const Color(0xFFFEFCF1),
      onSurface: const Color(0xFF383831),
      surfaceContainerLowest: const Color(0xFFF5F3E8),
      surfaceContainerLow: const Color(0xFFEFEDE2),
      surfaceContainer: const Color(0xFFE9E7DC),
      surfaceContainerHigh: const Color(0xFFE3E1D6),
      surfaceContainerHighest: const Color(0xFFDDDCD1),
      onSurfaceVariant: const Color(0xFF44443C),
      outline: const Color(0xFF75756D),
      outlineVariant: const Color(0xFFC6C5BA),
      shadow: const Color(0xFF383831),
      scrim: const Color(0xFF000000),
      inverseSurface: const Color(0xFF303029),
      onInverseSurface: const Color(0xFFF5F3E8),
      inversePrimary: const Color(0xFF8BCBA0),
    );

    final textTheme = TextTheme(
      displayLarge: GoogleFonts.notoSerif(
        fontSize: 57,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: colorScheme.onSurface,
      ),
      displayMedium: GoogleFonts.notoSerif(
        fontSize: 45,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: colorScheme.onSurface,
      ),
      displaySmall: GoogleFonts.notoSerif(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
        color: colorScheme.onSurface,
      ),
      headlineLarge: GoogleFonts.notoSerif(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
        color: colorScheme.onSurface,
      ),
      headlineMedium: GoogleFonts.notoSerif(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: colorScheme.onSurface,
      ),
      headlineSmall: GoogleFonts.notoSerif(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: colorScheme.onSurface,
      ),
      titleLarge: GoogleFonts.plusJakartaSans(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: colorScheme.onSurface,
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        color: colorScheme.onSurface,
      ),
      titleSmall: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: colorScheme.onSurface,
      ),
      bodyLarge: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        color: colorScheme.onSurface,
      ),
      bodyMedium: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        color: colorScheme.onSurface,
      ),
      bodySmall: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        color: colorScheme.onSurface,
      ),
      labelLarge: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: colorScheme.onSurface,
      ),
      labelMedium: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: colorScheme.onSurface,
      ),
      labelSmall: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: colorScheme.onSurface,
      ),
    );

    return MaterialApp(
      title: 'NCAF 2026 Timer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        textTheme: textTheme,
        scaffoldBackgroundColor: colorScheme.surface,
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            textStyle: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            textStyle: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: colorScheme.surfaceContainerLow,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: colorScheme.primary,
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
      home: const TimerHomePage(),
    );
  }
}
