import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_providers.dart';

class AuthFormState {
  const AuthFormState({
    this.isLoading = false,
    this.obscurePassword = true,
    this.errorMessage,
  });

  final bool isLoading;
  final bool obscurePassword;
  final String? errorMessage;
}

enum SignUpResult { signedIn, confirmationRequired, failed }

class AuthFormViewModel extends Notifier<AuthFormState> {
  @override
  AuthFormState build() => const AuthFormState();

  void togglePasswordVisibility() {
    state = AuthFormState(
      obscurePassword: !state.obscurePassword,
      errorMessage: state.errorMessage,
    );
  }

  void clearError() {
    state = AuthFormState(obscurePassword: state.obscurePassword);
  }

  Future<bool> signIn({required String email, required String password}) async {
    _startLoading();
    try {
      await ref
          .read(authRepositoryProvider)
          .signIn(email: email, password: password);
      _finishLoading();
      return true;
    } on AuthException catch (error) {
      _fail(_friendlyAuthError(error));
    } on PostgrestException {
      _fail(
        'Sua conta foi autenticada, mas não foi possível preparar o perfil.',
      );
    } catch (_) {
      _fail(
        'Não foi possível entrar. Verifique sua conexão e tente novamente.',
      );
    }
    return false;
  }

  Future<SignUpResult> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    _startLoading();
    try {
      final response = await ref
          .read(authRepositoryProvider)
          .signUp(name: name, email: email, password: password);
      _finishLoading();
      return response.session == null
          ? SignUpResult.confirmationRequired
          : SignUpResult.signedIn;
    } on AuthException catch (error) {
      _fail(_friendlyAuthError(error));
    } on PostgrestException {
      _fail('A conta foi criada, mas não foi possível preparar o perfil.');
    } catch (_) {
      _fail('Não foi possível criar sua conta. Tente novamente.');
    }
    return SignUpResult.failed;
  }

  Future<bool> sendPasswordReset(String email) async {
    _startLoading();
    try {
      await ref.read(authRepositoryProvider).sendPasswordReset(email);
      _finishLoading();
      return true;
    } on AuthException catch (error) {
      _fail(_friendlyAuthError(error));
    } catch (_) {
      _fail('Não foi possível enviar o e-mail de recuperação.');
    }
    return false;
  }

  Future<void> signOut() => ref.read(authRepositoryProvider).signOut();

  void _startLoading() {
    state = AuthFormState(
      isLoading: true,
      obscurePassword: state.obscurePassword,
    );
  }

  void _finishLoading() {
    state = AuthFormState(obscurePassword: state.obscurePassword);
  }

  void _fail(String message) {
    state = AuthFormState(
      obscurePassword: state.obscurePassword,
      errorMessage: message,
    );
  }

  String _friendlyAuthError(AuthException error) {
    final message = error.message.toLowerCase();
    if (message.contains('invalid login credentials')) {
      return 'E-mail ou senha incorretos.';
    }
    if (message.contains('email not confirmed')) {
      return 'Confirme seu e-mail antes de entrar.';
    }
    if (message.contains('already registered') ||
        message.contains('already been registered')) {
      return 'Já existe uma conta com este e-mail.';
    }
    if (message.contains('password')) {
      return 'A senha não atende aos requisitos de segurança.';
    }
    return 'Não foi possível concluir a autenticação. Tente novamente.';
  }
}

final authFormViewModelProvider =
    NotifierProvider<AuthFormViewModel, AuthFormState>(AuthFormViewModel.new);
