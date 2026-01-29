import 'package:flutter/material.dart';

extension StringExtensions on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }

  String toTitleCase() {
    return split(' ').map((word) => word.capitalize()).join(' ');
  }

  bool get isValidEmail {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    );
    return emailRegex.hasMatch(this);
  }

  bool get isValidPhone {
    final phoneRegex = RegExp(r'^[+]?[\d\s\-]{8,}$');
    return phoneRegex.hasMatch(this);
  }

  bool get isNullOrEmpty => isEmpty;

  bool get isNotNullOrEmpty => isNotEmpty;
}

extension DateTimeExtensions on DateTime {
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inSeconds < 60) {
      return 'hace ${difference.inSeconds} seg';
    } else if (difference.inMinutes < 60) {
      return 'hace ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'hace ${difference.inHours} h';
    } else if (difference.inDays < 30) {
      return 'hace ${difference.inDays} días';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return 'hace $months meses';
    } else {
      final years = (difference.inDays / 365).floor();
      return 'hace $years años';
    }
  }

  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year && 
           month == tomorrow.month && 
           day == tomorrow.day;
  }

  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year && 
           month == yesterday.month && 
           day == yesterday.day;
  }
}

extension BuildContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  double get screenWidth => mediaQuery.size.width;
  double get screenHeight => mediaQuery.size.height;
  bool get isDarkMode => theme.brightness == Brightness.dark;
  bool get isLandscape => mediaQuery.orientation == Orientation.landscape;
  bool get isPortrait => mediaQuery.orientation == Orientation.portrait;
  
  // Métodos para navegación segura
  void safePop() {
    if (Navigator.canPop(this)) {
      Navigator.pop(this);
    }
  }
}