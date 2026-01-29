import 'package:tapsi/core/constants/app_routes.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; 
import 'package:tapsi/presentation/features/auth/cubit/auth_cubit.dart'; 
import 'dart:async';
import '../../home/screens/home_screen.dart'; 
import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/text_styles.dart';
import '../../../../core/utils/validators.dart'; 
import '../../../../core/utils/helpers.dart';

class OTPScreen extends StatefulWidget {
  final String phoneNumber;
  
  const OTPScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  bool _isResendEnabled = false;
  int _resendSeconds = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel(); // Cancela timer anterior
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      setState(() {
        if (_resendSeconds > 0) {
          _resendSeconds--;
        } else {
          _isResendEnabled = true;
          timer.cancel();
        }
      });
    });
  }

  Future<void> _handleVerify() async {
    // Si el widget no existe, no hacer nada
    if (!mounted) {
      return;
    }
    
    final otpError = Validators.validateOTP(_otpController.text);
    if (otpError != null) {
      if (mounted) {
        Helpers.showSnackBar(context, otpError, isError: true);
      }
      return;
    }

    // Verificar nuevamente si mounted
    if (!mounted) return;
    
    // Usar un enfoque diferente para setState
    try {
      // Hacer setState solo si mounted
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }
      
      final authCubit = BlocProvider.of<AuthCubit>(context);
      await authCubit.verifyCode(_otpController.text, widget.phoneNumber);
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      // Solo hacer setState si el widget sigue existiendo
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      });
    }
  }

  void _handleResend() {
    if (!_isResendEnabled) return;

    setState(() {
      _isResendEnabled = false;
      _resendSeconds = 60;
    });

    // TODO: Resend code logic
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificación'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            Text(
              'Verifica tu número',
              style: AppTextStyles.h2.copyWith(
                color: isDark 
                    ? AppColors.darkTextPrimary 
                    : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enviamos un código al ${widget.phoneNumber}',
              style: AppTextStyles.body.copyWith(
                color: isDark 
                    ? AppColors.darkTextSecondary 
                    : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 48),
            
            // Campo OTP
            PinCodeTextField(
              appContext: context,
              length: 4,
              controller: _otpController,
              keyboardType: TextInputType.number,
              animationType: AnimationType.fade,
              pinTheme: PinTheme(
                shape: PinCodeFieldShape.box,
                borderRadius: BorderRadius.circular(12),
                fieldHeight: 56,
                fieldWidth: 56,
                activeFillColor: isDark 
                    ? AppColors.darkSurface 
                    : AppColors.lightSurface,
                activeColor: AppColors.primary,
                selectedFillColor: isDark 
                    ? AppColors.darkSurface 
                    : AppColors.lightSurface,
                selectedColor: AppColors.primary,
                inactiveFillColor: isDark 
                    ? AppColors.darkSurface 
                    : AppColors.lightSurface,
                inactiveColor: isDark 
                    ? AppColors.darkBorder 
                    : AppColors.lightBorder,
              ),
              animationDuration: const Duration(milliseconds: 300),
              enableActiveFill: true,
              onChanged: (value) {},
              onCompleted: (value) {
                Future.delayed(Duration.zero, () {
                  if (mounted) {
                    _handleVerify();
                  }
                });
              },
            ),
            
            const SizedBox(height: 32),
            
            // Temporizador para reenviar
            Center(
              child: _isResendEnabled
                  ? TextButton(
                      onPressed: _handleResend,
                      child: Text(
                        'Reenviar código',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : Text(
                      'Reenviar código en $_resendSeconds segundos',
                      style: AppTextStyles.body.copyWith(
                        color: isDark 
                            ? AppColors.darkTextSecondary 
                            : AppColors.lightTextSecondary,
                      ),
                    ),
            ),
            
            const SizedBox(height: 48),
            
            // Botón de verificar
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : () {
                  Future.delayed(Duration.zero, () {
                    if (mounted) {
                      _handleVerify();
                    }
                  });
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : Text(
                        'Verificar',
                        style: AppTextStyles.button.copyWith(color: AppColors.white),
                      ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Nota
            Text(
              'Si no recibes el código, verifica que el número sea correcto o intenta nuevamente en unos minutos.',
              style: AppTextStyles.small.copyWith(
                color: isDark 
                    ? AppColors.darkTextSecondary 
                    : AppColors.lightTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}