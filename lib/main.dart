import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'bindings/performance_counter.dart';
import 'views/feig_reader_view.dart';

const _brandBlue = Color(0xFF1D4ED8);
const _brandBlueDark = Color(0xFF93C5FD);
const _slate900 = Color(0xFF0F172A);
const _slate50 = Color(0xFFF8FAFC);

void main() {
  PerformanceCounter.init();
  runApp(const ProviderScope(child: FeigReaderApp()));
}

class FeigReaderApp extends StatelessWidget {
  const FeigReaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FEIG Reader',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      home: const FeigReaderView(),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final primary = isDark ? _brandBlueDark : _brandBlue;
    final cs =
        ColorScheme.fromSeed(
          seedColor: _brandBlue,
          brightness: brightness,
        ).copyWith(
          primary: primary,
          onPrimary: isDark ? _slate900 : Colors.white,
          surface: isDark ? _slate900 : _slate50,
          onSurface: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
          onSurfaceVariant: isDark
              ? const Color(0xFFCBD5E1)
              : const Color(0xFF475569),
          outline: isDark ? const Color(0xFF64748B) : const Color(0xFFCBD5E1),
          outlineVariant: isDark
              ? const Color(0xFF334155)
              : const Color(0xFFE2E8F0),
        );
    final baseTextTheme = isDark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;
    final textTheme = GoogleFonts.robotoTextTheme(
      baseTextTheme,
    ).apply(bodyColor: cs.onSurface, displayColor: cs.onSurface);

    return ThemeData(
      colorScheme: cs,
      useMaterial3: true,
      scaffoldBackgroundColor: cs.surface,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.roboto(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
          color: cs.onPrimary,
        ),
      ),
      dividerTheme: DividerThemeData(color: cs.outlineVariant, thickness: 1),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: cs.primary,
          textStyle: GoogleFonts.roboto(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        selectedColor: cs.primary,
        backgroundColor: cs.surface,
        labelStyle: GoogleFonts.roboto(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide(color: cs.outlineVariant),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cs.surfaceContainerLowest,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: cs.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        prefixIconColor: cs.onSurfaceVariant,
        labelStyle: GoogleFonts.roboto(fontSize: 14),
        hintStyle: GoogleFonts.roboto(fontSize: 14, color: cs.onSurfaceVariant),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          textStyle: GoogleFonts.roboto(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          textStyle: GoogleFonts.roboto(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
