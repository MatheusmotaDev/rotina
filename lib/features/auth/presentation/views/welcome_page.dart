import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'auth_form_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.event_available_rounded,
                  color: AppColors.primary,
                  size: 46,
                ),
              ),
              const SizedBox(height: 22),
              Text('Rotina', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 14),
              Text(
                'Organize sua rotina, foque no que importa e aumente sua produtividade.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 3),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => _openAuth(context, isSignUp: true),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Começar'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => _openAuth(context, isSignUp: false),
                child: const Text('Já tenho uma conta'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openAuth(BuildContext context, {required bool isSignUp}) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AuthFormPage(initialSignUp: isSignUp),
      ),
    );
  }
}
