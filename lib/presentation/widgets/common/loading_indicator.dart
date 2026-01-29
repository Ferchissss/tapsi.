import 'package:flutter/material.dart';
import 'package:tapsi/core/constants/colors.dart';

class LoadingIndicator extends StatelessWidget {
  final double size;
  final Color? color;
  final String? message;

  const LoadingIndicator({
    super.key,
    this.size = 40,
    this.color,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: color ?? AppColors.primary,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(
                fontSize: 14,
                color: isDark 
                    ? AppColors.darkTextSecondary 
                    : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ButtonLoadingIndicator extends StatelessWidget {
  final double size;
  final Color? color;

  const ButtonLoadingIndicator({
    super.key,
    this.size = 20,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: color ?? AppColors.white,
      ),
    );
  }
}

class FullScreenLoader extends StatelessWidget {
  final String? message;
  final bool withBackground;

  const FullScreenLoader({
    super.key,
    this.message,
    this.withBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      color: withBackground
          ? theme.scaffoldBackgroundColor
          : Colors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const LoadingIndicator(size: 50),
          if (message != null) ...[
            const SizedBox(height: 20),
            Text(
              message!,
              style: TextStyle(
                color: isDark 
                    ? AppColors.darkTextSecondary 
                    : AppColors.lightTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}