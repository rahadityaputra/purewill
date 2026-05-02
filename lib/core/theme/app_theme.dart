import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData light() {
    final baseTheme = ThemeData(
      primarySwatch: Colors.blue,
      useMaterial3: true,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );

    final interTextTheme = GoogleFonts.interTextTheme(baseTheme.textTheme);

    return ThemeData(
      primarySwatch: Colors.blue,
      useMaterial3: true,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      fontFamily: GoogleFonts.inter().fontFamily,
      textTheme: interTextTheme,
      primaryTextTheme: interTextTheme,
    );
  }
}
