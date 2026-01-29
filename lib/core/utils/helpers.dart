import 'package:flutter/material.dart';
import '../constants/colors.dart';

class Helpers {
  static void showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  static Future<void> showLoadingDialog(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: AppColors.primary,
                ),
                SizedBox(height: 16),
                Text('Cargando...'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static void hideLoadingDialog(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  static String getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'U';
  }

  static String formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'Hace unos segundos';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return 'Hace $minutes minuto${minutes == 1 ? '' : 's'}';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return 'Hace $hours hora${hours == 1 ? '' : 's'}';
    } else if (difference.inDays < 30) {
      final days = difference.inDays;
      return 'Hace $days día${days == 1 ? '' : 's'}';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return 'Hace $months mes${months == 1 ? '' : 'es'}';
    } else {
      final years = (difference.inDays / 365).floor();
      return 'Hace $years año${years == 1 ? '' : 's'}';
    }
  }
}