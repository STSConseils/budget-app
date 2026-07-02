import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pocketbase/pocketbase.dart' show ClientException;
import 'package:budget_app/core/theme.dart';
import 'package:budget_app/repositories/providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorMessage = '';
    });
    try {
      await ref.read(authRepoProvider).login(
            _emailController.text.trim(),
            _passwordController.text,
          );
      ref.invalidate(currentUserProvider);
      ref.invalidate(currentHouseholdProvider);
      if (mounted) context.go('/');
    } on ClientException catch (e) {
      final msg = (e.response['message'] as String? ?? '').toLowerCase();
      setState(() {
        _errorMessage = msg.contains('failed to authenticate')
            ? 'Email ou mot de passe incorrect.'
            : 'Connexion impossible. Réessayez.';
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'Connexion impossible. Réessayez.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Image.network(
                      'icons/Icon-192.png',
                      width: 96,
                      height: 96,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                  child: Text('FLOOZEE', style: AppTextStyles.hero),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      'LA FIN DU MOIS EN VERT',
                      style: AppTextStyles.sectionTitle,
                    ),
                  ),
                  const SizedBox(height: 48),
                  const Divider(height: 1),
                  const SizedBox(height: 32),
                  AutofillGroup(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _emailField(),
                          const SizedBox(height: 12),
                          _passwordField(),
                          const SizedBox(height: 24),
                          if (_errorMessage.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(
                                _errorMessage,
                                style: const TextStyle(
                                  color: AppColors.accent,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          _submitButton(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _emailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      autofillHints: const [AutofillHints.email],
      textInputAction: TextInputAction.next,
      style: AppTextStyles.body,
      decoration: _inputDeco('Email'),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Champ requis.';
        if (!v.contains('@')) return 'Email invalide.';
        return null;
      },
    );
  }

  Widget _passwordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: true,
      autofillHints: const [AutofillHints.password],
      textInputAction: TextInputAction.done,
      style: AppTextStyles.body,
      decoration: _inputDeco('Mot de passe'),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Champ requis.';
        if (v.length < 6) return 'Minimum 6 caractères.';
        return null;
      },
      onFieldSubmitted: (_) => _submit(),
    );
  }

  Widget _submitButton() {
    return ElevatedButton(
      onPressed: _loading ? null : _submit,
      child: _loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Text('Se connecter'),
    );
  }

  InputDecoration _inputDeco(String label) {
    const border = OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: AppColors.hairlineStrong),
    );
    const focused = OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: AppColors.ink, width: 1.5),
    );
    const error = OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: AppColors.accent),
    );
    return InputDecoration(
      labelText: label,
      labelStyle: AppTextStyles.body,
      filled: true,
      fillColor: Colors.white,
      border: border,
      enabledBorder: border,
      focusedBorder: focused,
      errorBorder: error,
      focusedErrorBorder: error,
    );
  }
}
