import 'package:flutter/material.dart';
import 'package:tapsi/core/constants/colors.dart';
import 'package:tapsi/core/constants/text_styles.dart';

class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isDisabled;
  final IconData? icon;
  final double? width;
  final double? height;
  final Color? borderColor;
  final Color? textColor;

  const SecondaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
    this.width,
    this.height,
    this.borderColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? 56,
      child: OutlinedButton(
        onPressed: (isDisabled || isLoading) ? null : onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: borderColor ?? AppColors.primary,
            width: 2,
          ),
          foregroundColor: textColor ?? AppColors.primary,
          disabledForegroundColor: isDark 
              ? AppColors.darkDisabled 
              : AppColors.lightDisabled,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: AppTextStyles.button.copyWith(
                      color: isDisabled
                          ? (isDark 
                              ? AppColors.darkDisabled 
                              : AppColors.lightDisabled)
                          : textColor ?? AppColors.primary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}