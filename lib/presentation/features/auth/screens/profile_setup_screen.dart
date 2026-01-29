import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tapsi/presentation/features/auth/cubit/auth_cubit.dart';
import 'package:tapsi/core/constants/colors.dart';
import 'package:tapsi/core/constants/text_styles.dart';
import 'package:tapsi/core/utils/validators.dart';

class ProfileSetupScreen extends StatefulWidget {
  final String phone;
  
  const ProfileSetupScreen({
    super.key,
    required this.phone,
  });

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
        print('📝 Iniciando completeProfile...');
        final authCubit = context.read<AuthCubit>();
        await authCubit.completeProfile(
        name: _nameController.text,
        email: _emailController.text.isNotEmpty ? _emailController.text : null,
        );
        print('✅ completeProfile exitoso');
        
    } catch (e) {
        print('❌ Error en completeProfile: $e');
        if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
            ),
        );
        }
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
        title: const Text('Completa tu perfil'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Text(
                '¡Bienvenido a Tapsi!',
                style: AppTextStyles.h2.copyWith(
                  color: isDark 
                      ? AppColors.darkTextPrimary 
                      : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Completa tu información para una mejor experiencia',
                style: AppTextStyles.body.copyWith(
                  color: isDark 
                      ? AppColors.darkTextSecondary 
                      : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 48),
              
              // Nombre (obligatorio)
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre completo *',
                  hintText: 'Ej: Juan Pérez',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: Validators.validateName,
              ),
              const SizedBox(height: 24),
              
              // Email (opcional)
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email (opcional)',
                  hintText: 'ejemplo@email.com',
                  prefixIcon: Icon(Icons.email),
                ),
                validator: Validators.validateEmail,
              ),
              const SizedBox(height: 48),
              
              // Botón de continuar
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitProfile,
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
                          style: AppTextStyles.button.copyWith(
                            color: AppColors.white,
                          ),
                        ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Nota
              Text(
                '* Campo obligatorio. Tu nombre se mostrará a los conductores.',
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
      ),
    );
  }
}