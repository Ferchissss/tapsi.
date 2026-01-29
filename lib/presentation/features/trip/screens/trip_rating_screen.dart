// lib/presentation/features/trip/screens/trip_rating_screen.dart

import 'package:flutter/material.dart';
import 'package:tapsi/core/constants/colors.dart';
import 'package:tapsi/core/constants/text_styles.dart';
import 'package:tapsi/data/models/trip_model.dart';
import 'package:tapsi/data/models/driver_model.dart';

class TripRatingScreen extends StatefulWidget {
  final TripModel trip;
  final DriverModel? driver;

  const TripRatingScreen({
    super.key,
    required this.trip,
    this.driver,
  });

  @override
  State<TripRatingScreen> createState() => _TripRatingScreenState();
}

class _TripRatingScreenState extends State<TripRatingScreen> {
  int _rating = 5;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  final List<String> _quickComments = [
    'Excelente conductor',
    'Vehículo limpio',
    'Muy amable',
    'Conducción segura',
    'Llegó puntual',
    'Buena música',
  ];

  final List<String> _selectedComments = [];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _toggleComment(String comment) {
    setState(() {
      if (_selectedComments.contains(comment)) {
        _selectedComments.remove(comment);
      } else {
        _selectedComments.add(comment);
      }
    });
  }

  Future<void> _submitRating() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      // Construir comentario final
      String finalComment = _commentController.text.trim();
      if (_selectedComments.isNotEmpty) {
        if (finalComment.isNotEmpty) {
          finalComment += '\n';
        }
        finalComment += _selectedComments.join(', ');
      }

      // TODO: Enviar calificación al backend
      await Future.delayed(const Duration(seconds: 2)); // Simulación

      if (!mounted) return;

      // Mostrar confirmación y volver al home
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Gracias por tu calificación!'),
          backgroundColor: AppColors.success,
        ),
      );

      // Volver al home (quitar todas las pantallas de viaje)
      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _skipRating() {
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: () async {
        _skipRating();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Calificar Viaje'),
          leading: const SizedBox.shrink(), // Sin botón de atrás
          actions: [
            TextButton(
              onPressed: _skipRating,
              child: Text(
                'Omitir',
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // Icono de éxito
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  size: 50,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 24),
              // Título
              Text(
                '¡Viaje completado!',
                style: AppTextStyles.h2.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Califica tu experiencia con el conductor',
                style: AppTextStyles.body.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // Información del conductor
              if (widget.driver != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Foto del conductor
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: widget.driver!.photoUrl != null
                            ? ClipOval(
                                child: Image.network(
                                  widget.driver!.photoUrl!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 30,
                              ),
                      ),
                      const SizedBox(width: 16),
                      // Info del conductor
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.driver!.name,
                              style: AppTextStyles.bodyBold,
                            ),
                            const SizedBox(height: 4),
                            if (widget.driver!.vehicle != null)
                              Text(
                                '${widget.driver!.vehicle!.brand} ${widget.driver!.vehicle!.model}',
                                style: AppTextStyles.caption.copyWith(
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 32),
              // Estrellas de calificación
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    iconSize: 48,
                    onPressed: () {
                      setState(() {
                        _rating = index + 1;
                      });
                    },
                    icon: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              Text(
                _getRatingText(_rating),
                style: AppTextStyles.bodyBold.copyWith(
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 32),
              // Comentarios rápidos
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Comentarios rápidos (opcional)',
                  style: AppTextStyles.bodyBold,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quickComments.map((comment) {
                  final isSelected = _selectedComments.contains(comment);
                  return FilterChip(
                    label: Text(comment),
                    selected: isSelected,
                    onSelected: (_) => _toggleComment(comment),
                    selectedColor: AppColors.primary.withOpacity(0.2),
                    checkmarkColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.primary : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              // Campo de comentario adicional
              TextField(
                controller: _commentController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Comentario adicional (opcional)',
                  hintText: '¿Algo más que quieras compartir?',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 32),
              // Botón de enviar
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitRating,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'ENVIAR CALIFICACIÓN',
                          style: AppTextStyles.button.copyWith(
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Muy malo';
      case 2:
        return 'Malo';
      case 3:
        return 'Regular';
      case 4:
        return 'Bueno';
      case 5:
        return '¡Excelente!';
      default:
        return '';
    }
  }
}