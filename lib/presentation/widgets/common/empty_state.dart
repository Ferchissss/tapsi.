import 'package:flutter/material.dart';
import 'package:tapsi/core/constants/colors.dart';
import 'package:tapsi/core/constants/text_styles.dart';

class EmptyState extends StatelessWidget {
  final String title;
  final String? description;
  final IconData icon;
  final Color? iconColor;
  final VoidCallback? onAction;
  final String? actionText;

  const EmptyState({
    super.key,
    required this.title,
    this.description,
    this.icon = Icons.search_off,
    this.iconColor,
    this.onAction,
    this.actionText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: iconColor ?? (isDark 
                  ? AppColors.darkDisabled 
                  : AppColors.lightDisabled),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: AppTextStyles.h3.copyWith(
                color: isDark 
                    ? AppColors.darkTextPrimary 
                    : AppColors.lightTextPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            if (description != null) ...[
              const SizedBox(height: 8),
              Text(
                description!,
                style: AppTextStyles.body.copyWith(
                  color: isDark 
                      ? AppColors.darkTextSecondary 
                      : AppColors.lightTextSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onAction != null && actionText != null) ...[
              const SizedBox(height: 32),
              SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: onAction,
                  child: Text(actionText!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}