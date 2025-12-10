// lib/src/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Definimos colores constantes para evitar "magic colors" dispersos
  static const Color primaryColor = Color(0xFF00C569); 
  static const Color darkColor = Color(0xFF1A1A1A);
  
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFF5F5F5), // Gris muy claro para fondo
      textTheme: GoogleFonts.poppinsTextTheme(), // Fuente moderna y legible
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent, // Estilo moderno "plano"
        foregroundColor: darkColor,
      ),
    );
  }
}