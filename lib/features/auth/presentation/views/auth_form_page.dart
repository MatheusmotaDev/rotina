import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../viewmodels/auth_form_view_model.dart';

class AuthFormPage extends ConsumerStatefulWidget {
  const AuthFormPage({required this.initialSignUp, super.key});

  final bool initialSignUp;

  @override
  ConsumerState<AuthFormPage> createState() => _AuthFormPageState();
}

class _AuthFormPageState extends ConsumerState<AuthFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmationController = TextEditingController();
  late bool _isSignUp;

  @override
  void initState() {
    super.initState();
    _isSignUp = widget.initialSignUp;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authFormViewModelProvider.notifier).clearError();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authFormViewModelProvider);

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            children: [
              Text(
                _isSignUp ? 'Crie sua conta' : 'Que bom ter você de volta',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                _isSignUp
                    ? 'Comece a planejar seus dias de forma mais realista.'
                    : 'Entre para continuar seu planejamento.',
              ),
              const SizedBox(height: 28),
              if (_isSignUp) ...[
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.name],
                  decoration: const InputDecoration(
                    labelText: 'Nome',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator: (value) => value == null || value.trim().length < 2
                      ? 'Informe seu nome.'
                      : null,
                ),
                const SizedBox(height: 14),
              ],
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'E-mail',
                  prefixIcon: Icon(Icons.mail_outline_rounded),
                ),
                validator: _validateEmail,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _passwordController,
                obscureText: state.obscurePassword,
                textInputAction: _isSignUp
                    ? TextInputAction.next
                    : TextInputAction.done,
                autofillHints: _isSignUp
                    ? const [AutofillHints.newPassword]
                    : const [AutofillHints.password],
                onFieldSubmitted: (_) {
                  if (!_isSignUp) _submit();
                },
                decoration: InputDecoration(
                  labelText: 'Senha',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    tooltip: state.obscurePassword
                        ? 'Mostrar senha'
                        : 'Ocultar senha',
                    onPressed: ref
                        .read(authFormViewModelProvider.notifier)
                        .togglePasswordVisibility,
                    icon: Icon(
                      state.obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: (value) => value == null || value.length < 8
                    ? 'Use pelo menos 8 caracteres.'
                    : null,
              ),
              if (_isSignUp) ...[
                const SizedBox(height: 14),
                TextFormField(
                  controller: _passwordConfirmationController,
                  obscureText: state.obscurePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: const InputDecoration(
                    labelText: 'Confirmar senha',
                    prefixIcon: Icon(Icons.lock_reset_rounded),
                  ),
                  validator: (value) => value != _passwordController.text
                      ? 'As senhas não coincidem.'
                      : null,
                ),
              ],
              if (state.errorMessage != null) ...[
                const SizedBox(height: 16),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    state.errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
              if (!_isSignUp)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: state.isLoading ? null : _resetPassword,
                    child: const Text('Esqueci minha senha'),
                  ),
                )
              else
                const SizedBox(height: 22),
              FilledButton(
                onPressed: state.isLoading ? null : _submit,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: state.isLoading
                    ? const SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isSignUp ? 'Criar conta' : 'Entrar'),
              ),
              const SizedBox(height: 14),
              TextButton(
                onPressed: state.isLoading
                    ? null
                    : () {
                        setState(() => _isSignUp = !_isSignUp);
                        ref
                            .read(authFormViewModelProvider.notifier)
                            .clearError();
                      },
                child: Text(
                  _isSignUp
                      ? 'Já tenho uma conta'
                      : 'Ainda não tenho uma conta',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    return valid ? null : 'Informe um e-mail válido.';
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final viewModel = ref.read(authFormViewModelProvider.notifier);
    if (_isSignUp) {
      final result = await viewModel.signUp(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (!mounted) return;
      if (result == SignUpResult.signedIn) {
        Navigator.of(context).pop();
      } else if (result == SignUpResult.confirmationRequired) {
        _showMessage(
          'Conta criada. Confirme o e-mail enviado antes de entrar.',
        );
        setState(() => _isSignUp = false);
        _passwordController.clear();
        _passwordConfirmationController.clear();
      }
      return;
    }

    final signedIn = await viewModel.signIn(
      email: _emailController.text,
      password: _passwordController.text,
    );
    if (signedIn && mounted) Navigator.of(context).pop();
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (_validateEmail(email) != null) {
      _showMessage('Informe seu e-mail para recuperar a senha.');
      return;
    }
    final sent = await ref
        .read(authFormViewModelProvider.notifier)
        .sendPasswordReset(email);
    if (sent && mounted) {
      _showMessage('Enviamos as instruções de recuperação para seu e-mail.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
