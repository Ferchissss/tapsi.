import 'package:flutter/material.dart';
import 'colors.dart';

class AppTextStyles {
  static const String fontFamily = '';
  
  // Tamaños de fuente
  static const double fontSizeH1 = 32.0;
  static const double fontSizeH2 = 24.0;
  static const double fontSizeH3 = 20.0;
  static const double fontSizeBody = 16.0;
  static const double fontSizeCaption = 14.0;
  static const double fontSizeSmall = 12.0;
  static const double fontSizeButton = 16.0;
  static const double fontSizeInput = 16.0;
  
  // Estilos base
  static TextStyle get h1 => TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeH1,
    fontWeight: FontWeight.bold,
    height: 1.2,
  );
  
  static TextStyle get h2 => TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeH2,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );
  
  static TextStyle get h3 => TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeH3,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );
  
  static TextStyle get body => TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeBody,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );
  
  static TextStyle get bodyBold => TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeBody,
    fontWeight: FontWeight.bold,
    height: 1.5,
  );
  
  static TextStyle get caption => TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeCaption,
    fontWeight: FontWeight.normal,
    height: 1.4,
  );
  
  static TextStyle get small => TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeSmall,
    fontWeight: FontWeight.normal,
    height: 1.3,
  );
  
  static TextStyle get button => TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeButton,
    fontWeight: FontWeight.w600,
    height: 1.0,
    letterSpacing: 0.5,
  );
  
  static TextStyle get input => TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeInput,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );
  
  // Métodos de ayuda para aplicar colores
  static TextStyle h1Light({Color? color}) => h1.copyWith(color: color ?? AppColors.lightTextPrimary);
  static TextStyle h1Dark({Color? color}) => h1.copyWith(color: color ?? AppColors.darkTextPrimary);
  
  static TextStyle h2Light({Color? color}) => h2.copyWith(color: color ?? AppColors.lightTextPrimary);
  static TextStyle h2Dark({Color? color}) => h2.copyWith(color: color ?? AppColors.darkTextPrimary);
  
  static TextStyle bodyLight({Color? color}) => body.copyWith(color: color ?? AppColors.lightTextPrimary);
  static TextStyle bodyDark({Color? color}) => body.copyWith(color: color ?? AppColors.darkTextPrimary);
}