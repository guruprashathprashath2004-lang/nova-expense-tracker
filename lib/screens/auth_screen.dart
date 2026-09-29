import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';
import '../core/glass/glass.dart';
import '../providers/auth_provider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool isLoading = false;
  bool isRegistering = false;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  String? _submitError;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      _submitError = null;
    });
    try {
      final auth = ref.read(authProvider.notifier);
      if (isRegistering) {
        await auth.register(
          displayName: nameController.text,
          email: emailController.text,
          password: passwordController.text,
        );
      } else {
        await auth.signIn(
          email: emailController.text,
          password: passwordController.text,
        );
      }
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() => _submitError = _authErrorMessage(error));
    } on FirebaseException catch (error) {
      if (!mounted) return;
      setState(() => _submitError =
          error.message ?? 'Unable to complete authentication.');
    } on StateError catch (error) {
      if (!mounted) return;
      setState(() => _submitError = error.message);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  String _authErrorMessage(FirebaseAuthException error) => switch (error.code) {
        'invalid-credential' ||
        'invalid-login-credentials' ||
        'wrong-password' ||
        'user-not-found' =>
          'Email or password is incorrect.',
        'email-already-in-use' => 'An account already exists for this email.',
        'weak-password' => 'Choose a password with at least 8 characters.',
        'invalid-email' => 'Enter a valid email address.',
        'network-request-failed' =>
          'Network unavailable. Check your connection and retry.',
        'user-disabled' => error.message ?? 'This account has been disabled.',
        _ => error.message ?? 'Unable to authenticate. Please try again.',
      };

  Future<void> _sendPasswordReset() async {
    final email = emailController.text.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid email address first.')),
      );
      return;
    }
    try {
      await ref.read(authProvider.notifier).sendPasswordReset(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent.')),
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_authErrorMessage(error))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authSession = ref.watch(authProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedGradientBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: GlassCard(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Form(
                  key: _formKey,
                  child: SizedBox(
                    width: 420,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Welcome back',
                                style:
                                    Theme.of(context).textTheme.headlineSmall,
                              ),
                            ),
                            const ThemeToggleButton(),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          isRegistering
                              ? 'Create your Nova account'
                              : 'Sign in to Nova',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        if (_submitError != null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            _submitError!,
                            key: const Key('auth-submit-error'),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                        if (authSession.errorMessage != null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            authSession.errorMessage!,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.xl),
                        if (isRegistering) ...[
                          TextFormField(
                            controller: nameController,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Full name',
                              prefixIcon: Icon(Icons.person_rounded),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                    ? 'Enter your name'
                                    : null,
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        TextFormField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_rounded),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Enter email';
                            }
                            if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                .hasMatch(value.trim())) {
                              return 'Enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: passwordController,
                          obscureText: !_passwordVisible,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_rounded),
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              tooltip: _passwordVisible
                                  ? 'Hide password'
                                  : 'Show password',
                              onPressed: () => setState(
                                () => _passwordVisible = !_passwordVisible,
                              ),
                              icon: Icon(
                                _passwordVisible
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter password';
                            }
                            if (isRegistering && value.length < 8) {
                              return 'Use at least 8 characters';
                            }
                            return null;
                          },
                        ),
                        if (isRegistering) ...[
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: confirmPasswordController,
                            obscureText: !_confirmPasswordVisible,
                            decoration: InputDecoration(
                              labelText: 'Confirm password',
                              prefixIcon:
                                  const Icon(Icons.lock_outline_rounded),
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                tooltip: _confirmPasswordVisible
                                    ? 'Hide confirm password'
                                    : 'Show confirm password',
                                onPressed: () => setState(
                                  () => _confirmPasswordVisible =
                                      !_confirmPasswordVisible,
                                ),
                                icon: Icon(
                                  _confirmPasswordVisible
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                ),
                              ),
                            ),
                            validator: (value) =>
                                value != passwordController.text
                                    ? 'Passwords do not match'
                                    : null,
                          ),
                        ] else ...[
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: isLoading ? null : _sendPasswordReset,
                              child: const Text('Forgot password?'),
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.xl),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: isLoading ? null : _submit,
                            icon: isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.login_rounded),
                            label: Text(
                              isLoading
                                  ? (isRegistering
                                      ? 'Creating account...'
                                      : 'Signing in...')
                                  : (isRegistering
                                      ? 'Create account'
                                      : 'Sign in'),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Align(
                          alignment: Alignment.center,
                          child: TextButton(
                            onPressed: isLoading
                                ? null
                                : () => setState(
                                    () => isRegistering = !isRegistering),
                            child: Text(
                              isRegistering
                                  ? 'Already have an account? Sign in'
                                  : 'Create a new account',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
