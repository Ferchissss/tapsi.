import 'package:flutter/material.dart';

class AppColors {
  // Colores principales basados en tu paleta
  static const Color eminence = Color(0xFF5F2977);        // #5F2977
  static const Color vividViolet = Color(0xFF7E3E9B);     // #7E3E9B
  static const Color concrete = Color(0xFFF3F3F3);        // #F3F3F3
  static const Color valentino = Color(0xFF39114B);       // #39114B
  static const Color amethystSmoke = Color(0xFFAE8EBB);   // #AE8EBB
  static const Color affair = Color(0xFF774C88);          // #774C88
  static const Color londonHue = Color(0xFFC5ADCE);       // #C5ADCE
  static const Color snuff = Color(0xFFDDCFE1);           // #DDCFE1

  // Colores principales (mapeando a tu paleta)
  static const Color primary = eminence;                 // #5F2977
  static const Color secondary = valentino;              // #39114B
  static const Color accent = vividViolet;               // #7E3E9B

  // Estados (manteniendo los mismos para consistencia)
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // Modo Claro (usando tu paleta)
  static const Color lightBackground = concrete;         // #F3F3F3
  static const Color lightSurface = Colors.white;
  static const Color lightBorder = londonHue;            // #C5ADCE
  static const Color lightDisabled = amethystSmoke;      // #AE8EBB
  static const Color lightTextPrimary = valentino;       // #39114B
  static const Color lightTextSecondary = affair;        // #774C88
  static const Color lightTextHint = snuff;              // #DDCFE1

  // Modo Oscuro (usando tu paleta adaptada)
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkBorder = Color(0xFF303030);
  static const Color darkDisabled = Color(0xFF666666);
  static const Color darkTextPrimary = Colors.white;
  static const Color darkTextSecondary = Color(0xFFB0B0B0);
  static const Color darkTextHint = Color(0xFF666666);

  // Especiales (ajustando según tu paleta)
  static const Color taxiYellow = Color(0xFFFFC107);
  static const Color emergencyRed = Color(0xFFD32F2F);
  static const Color onlineGreen = Color(0xFF4CAF50);
  static const Color transparent = Colors.transparent;
  static const Color white = Colors.white;
  static const Color black = Colors.black;

  // Gradientes usando tu paleta
  static LinearGradient get primaryGradient => LinearGradient(
        colors: [eminence, vividViolet],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get secondaryGradient => LinearGradient(
        colors: [valentino, affair],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  // Métodos de ayuda para obtener colores específicos
  static Color get brandPurple => eminence;
  static Color get brandLightPurple => vividViolet;
  static Color get brandDarkPurple => valentino;
  static Color get brandGray => concrete;
}