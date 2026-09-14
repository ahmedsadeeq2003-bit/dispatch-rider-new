import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_textfield.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _authService = AuthService();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  void _register() async {
    setState(() => _loading = true);
    final error = await _authService.registerUser(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      name: _nameController.text.trim(),
      context: context,
    );
    if (!mounted) return;
    setState(() => _loading = false);

    if (error == null) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 60),
            Lottie.asset('assets/animations/Delivery Riding.json', height: 180),
            const SizedBox(height: AppSpacing.md),

            Text('Create Account', style: AppText.h1),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Join Dispatch Rider and start sending packages fast & safe!',
              textAlign: TextAlign.center,
              style: AppText.bodyMuted,
            ),
            const SizedBox(height: AppSpacing.xl),

            CustomTextField(
              controller: _nameController,
              label: 'Full Name',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: AppSpacing.md),

            CustomTextField(
              controller: _emailController,
              label: 'Email',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: AppSpacing.md),

            CustomTextField(
              controller: _passwordController,
              label: 'Password',
              icon: Icons.lock_outline,
              isPassword: true,
            ),
            const SizedBox(height: AppSpacing.lg),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _loading ? null : _register,
                child: _loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Register'),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Already have an account? ', style: AppText.bodyMuted),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/login'),
                  child: Text(
                    'Login',
                    style: AppText.body.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
