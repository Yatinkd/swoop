import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../main.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;
  final supabase = Supabase.instance.client;

  Future<void> signup() async {
    setState(() => isLoading = true);
    try {
      await supabase.auth.signUp(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          backgroundColor: AppColors.navy,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text('Create account', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.navy))),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(),
              Icon(Icons.person_add_alt_1_outlined, size: 56, color: AppColors.navyMid),
              const SizedBox(height: 20),
              Text('Join Swoop', style: AppTextStyles.sectionHeading.copyWith(fontSize: 24)),
              const SizedBox(height: 8),
              Text(
                'Create an account to start finding your crew',
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(color: AppColors.navyLight),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textBody),
                decoration: const InputDecoration(hintText: 'Email address'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: passwordController,
                obscureText: true,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textBody),
                decoration: const InputDecoration(hintText: 'Password (min 6 chars)'),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : signup,
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Create account'),
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
