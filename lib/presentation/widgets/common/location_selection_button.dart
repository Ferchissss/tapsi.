import 'package:flutter/material.dart';
import 'package:tapsi/core/constants/colors.dart';
import 'package:tapsi/core/constants/text_styles.dart';
import 'package:tapsi/data/models/location_model.dart';

class LocationSelectionButton extends StatelessWidget {
  final String label;
  final String? address;
  final String hintText;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback? onMapTap;
  final VoidCallback? onClearTap;
  final bool showClearButton;

  const LocationSelectionButton({
    super.key,
    required this.label,
    required this.hintText,
    required this.onTap,
    this.address,
    this.isActive = false,
    this.onMapTap,
    this.onClearTap,
    this.showClearButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? AppColors.primary : 
                 isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: isActive ? 2 : 1,
        ),
        boxShadow: [
          if (isActive)
            BoxShadow(
              color: AppColors.primary.withOpacity(0.1),
              blurRadius: 8,
              spreadRadius: 2,
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Icono
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary : 
                           isDark ? AppColors.darkDisabled : AppColors.lightDisabled,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    label.toLowerCase().contains('origen') ? 
                      Icons.location_on : Icons.location_pin,
                    color: isActive ? AppColors.white : 
                           isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    size: 20,
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Texto
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: AppTextStyles.caption.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      address != null
                          ? Text(
                              address!,
                              style: AppTextStyles.body.copyWith(
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          : Text(
                              hintText,
                              style: AppTextStyles.body.copyWith(
                                color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint,
                              ),
                            ),
                    ],
                  ),
                ),
                
                // Botones de acción
                Row(
                  children: [
                    // Botón de mapa
                    if (onMapTap != null)
                      IconButton(
                        icon: Icon(
                          Icons.map,
                          size: 20,
                          color: AppColors.primary,
                        ),
                        onPressed: onMapTap,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                      ),
                    
                    // Botón de limpiar
                    if (showClearButton && onClearTap != null)
                      IconButton(
                        icon: Icon(
                          Icons.clear,
                          size: 20,
                          color: AppColors.error,
                        ),
                        onPressed: onClearTap,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}