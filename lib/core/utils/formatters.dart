import 'package:intl/intl.dart';

class Formatters {
  static final _currencyFormat = NumberFormat.currency(
    symbol: 'S/ ',
    decimalDigits: 2,
  );
  
  static final _dateFormat = DateFormat('dd/MM/yyyy');
  static final _timeFormat = DateFormat('HH:mm');
  static final _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');

  static String formatCurrency(double amount) {
    return _currencyFormat.format(amount);
  }

  static String formatDate(DateTime date) {
    return _dateFormat.format(date);
  }

  static String formatTime(DateTime date) {
    return _timeFormat.format(date);
  }

  static String formatDateTime(DateTime date) {
    return _dateTimeFormat.format(date);
  }

  static String formatPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    
    if (cleaned.startsWith('+') && cleaned.length >= 12) {
      return '${cleaned.substring(0, 3)} ${cleaned.substring(3, 6)} ${cleaned.substring(6, 9)} ${cleaned.substring(9)}';
    } else if (cleaned.length >= 9) {
      return '${cleaned.substring(0, 3)} ${cleaned.substring(3, 6)} ${cleaned.substring(6)}';
    }
    return cleaned;
  }

  static String formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    }
    
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    
    if (remainingMinutes == 0) {
      return '$hours h';
    }
    
    return '$hours h $remainingMinutes min';
  }

  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toInt()} m';
    }
    
    final kilometers = meters / 1000;
    return '${kilometers.toStringAsFixed(1)} km';
  }

  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return '${text[0].toUpperCase()}${text.substring(1).toLowerCase()}';
  }

  static String capitalizeWords(String text) {
    return text.split(' ').map((word) => capitalize(word)).join(' ');
  }
}