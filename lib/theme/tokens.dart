import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const seed = Color(0xFF26C6DA);
  static const surface = Colors.white;
  static const background = Color(0xFFEFF7F9);

  static ColorScheme lightScheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.light,
  );

  static ColorScheme darkScheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.dark,
  );
}

class AppTypography {
  static TextTheme textTheme(Brightness brightness) {
    final base = GoogleFonts.poppinsTextTheme();
    return base;
  }
}

class AppRadii {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double pill = 999;
}

class AppSpace {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
}

class AppDurations {
  static const fast = Duration(milliseconds: 150);
  static const normal = Duration(milliseconds: 250);
  static const slow = Duration(milliseconds: 350);
}
