import 'package:flutter/material.dart';

class Validators {
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'El teléfono es obligatorio';
    }
    
    // Eliminar espacios y caracteres especiales
    final phone = value.replaceAll(RegExp(r'[^\d+]'), '');
    
    if (phone.length < 8) {
      return 'El teléfono debe tener al menos 8 dígitos';
    }
    
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    );
    
    if (!emailRegex.hasMatch(value)) {
      return 'Ingresa un email válido';
    }
    
    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'El nombre es obligatorio';
    }
    
    if (value.length < 2) {
      return 'El nombre debe tener al menos 2 caracteres';
    }
    
    return null;
  }

  static String? validateOTP(String? value) {
    if (value == null || value.isEmpty) {
      return 'El código es obligatorio';
    }
    
    if (value.length != 4) {
      return 'El código debe tener 4 dígitos';
    }
    
    if (!RegExp(r'^\d{4}$').hasMatch(value)) {
      return 'Solo se permiten números';
    }
    
    return null;
  }

  static String? validateNotEmpty(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'El campo $fieldName es obligatorio';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es obligatoria';
    }
    
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    
    return null;
  }
}