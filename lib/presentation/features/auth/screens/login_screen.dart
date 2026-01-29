import 'package:tapsi/core/constants/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tapsi/presentation/features/auth/cubit/auth_cubit.dart'; 

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/text_styles.dart';
import '../../../../core/theme/theme_manager.dart';
import '../../../../core/utils/validators.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  String _countryCode = '+591'; // Perú por defecto
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final phoneNumber = '$_countryCode${_phoneController.text}';
      
      // LLAMAR AL CUBIT
      final authCubit = context.read<AuthCubit>();
      await authCubit.sendVerificationCode(phoneNumber);
      
      // La navegación la maneja el cubit
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              Provider.of<ThemeManager>(context, listen: false).toggleTheme();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Text(
                'Ingresa tu número',
                style: AppTextStyles.h2.copyWith(
                  color: isDark 
                      ? AppColors.darkTextPrimary 
                      : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Te enviaremos un código de verificación',
                style: AppTextStyles.body.copyWith(
                  color: isDark 
                      ? AppColors.darkTextSecondary 
                      : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 48),
              
              // Selector de país simplificado
              Row(
                children: [
                  // Selector de código de país
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    child: CountryCodePicker(
                      onChanged: (country) {
                        setState(() {
                          _countryCode = country.dialCode ?? '+591';
                        });
                      },
                      initialSelection: 'BO',
                      favorite: ['BO', 'MX', 'PE', 'AR', 'BR'],
                      showCountryOnly: false,
                      showOnlyCountryWhenClosed: false,
                      alignLeft: false,
                      showFlag: true,
                      showFlagDialog: true,
                      hideSearch: false,
                      textStyle: AppTextStyles.body.copyWith(
                        color: isDark 
                            ? AppColors.darkTextPrimary 
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Campo de teléfono
                  Expanded(
                    child: TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: AppTextStyles.input.copyWith(
                        color: isDark 
                            ? AppColors.darkTextPrimary 
                            : AppColors.lightTextPrimary,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Número de teléfono',
                        hintText: '99 99 99 99',
                      ),
                      validator: Validators.validatePhone,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 48),
              
              // Botón de continuar
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
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
                          'Continuar',
                          style: AppTextStyles.button.copyWith(color: AppColors.white),
                        ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Términos y condiciones
              Text.rich(
                TextSpan(
                  text: 'Al continuar, aceptas nuestros ',
                  style: AppTextStyles.small.copyWith(
                    color: isDark 
                        ? AppColors.darkTextSecondary 
                        : AppColors.lightTextSecondary,
                  ),
                  children: [
                    TextSpan(
                      text: 'Términos de Servicio',
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(text: ' y '),
                    TextSpan(
                      text: 'Política de Privacidad',
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}