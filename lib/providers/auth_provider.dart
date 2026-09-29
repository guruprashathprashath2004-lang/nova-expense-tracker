import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import '../services/firebase_auth_service.dart';

class AuthSession {
  final bool isAuthenticated;
  final String email;
  final String uid;
  final String displayName;
  final String currencyCode;
  final bool isLoading;
  final String? errorMessage;

  const AuthSession({
    required this.isAuthenticated,
    required this.email,
    this.uid = '',
    this.displayName = '',
    this.currencyCode = 'LKR',
    this.isLoading = false,
    this.errorMessage,
  });

  AuthSession copyWith({
    bool? isAuthenticated,
    String? email,
    String? uid,
    String? displayName,
    String? currencyCode,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthSession(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      email: email ?? this.email,
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      currencyCode: currencyCode ?? this.currencyCode,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  factory AuthSession.fromProfile(UserProfile profile) => AuthSession(
        isAuthenticated: true,
        email: profile.email,
        uid: profile.uid,
        displayName: profile.displayName,
        currencyCode: profile.currencyCode,
      );
}

class AuthNotifier extends StateNotifier<AuthSession> {
  AuthNotifier(this._authService)
      : super(const AuthSession(isAuthenticated: false, email: '')) {
    _authStateSubscription = _authService.authStateChanges.listen((user) {
      if (user == null) {
        if (state.isAuthenticated) {
          state = const AuthSession(isAuthenticated: false, email: '');
        }
      } else if (state.uid != user.uid && !state.isLoading) {
        unawaited(_restoreSession());
      }
    });
    _restoreSession();
  }

  final FirebaseAuthService _authService;
  late final StreamSubscription<User?> _authStateSubscription;

  Future<void> _restoreSession() async {
    if (_authService.currentUser == null) return;
    state = state.copyWith(isLoading: true);
    try {
      final profile = await _authService.loadCurrentProfile();
      state = AuthSession.fromProfile(profile);
    } on FirebaseAuthException catch (error) {
      state = AuthSession(
        isAuthenticated: false,
        email: '',
        errorMessage: error.message ?? 'Could not restore the saved session.',
      );
    } on FirebaseException catch (error) {
      state = AuthSession(
        isAuthenticated: false,
        email: '',
        errorMessage: error.message ?? 'Could not load your account profile.',
      );
    } on StateError catch (error) {
      await _authService.signOut();
      state = AuthSession(
        isAuthenticated: false,
        email: '',
        errorMessage: error.message,
      );
    } finally {
      if (state.isLoading) state = state.copyWith(isLoading: false);
    }
  }

  Future<void> signIn({required String email, String? password}) async {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty) {
      throw ArgumentError('Email is required');
    }

    if (password == null || password.isEmpty) {
      throw ArgumentError('Password is required');
    }

    state = state.copyWith(isLoading: true);
    try {
      final credential = await _authService.signInWithEmail(
        email: trimmedEmail,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw StateError('Authentication succeeded without a user profile.');
      }
      UserProfile profile;
      try {
        profile = await _authService.loadProfile(user.uid);
      } on StateError {
        await _authService.signOut();
        rethrow;
      }
      state = AuthSession.fromProfile(profile);
    } catch (_) {
      state = const AuthSession(isAuthenticated: false, email: '');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    state = const AuthSession(isAuthenticated: false, email: '');
  }

  Future<void> register({
    required String displayName,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final profile = await _authService.registerWithEmail(
        displayName: displayName.trim(),
        email: email.trim(),
        password: password,
      );
      state = AuthSession.fromProfile(profile);
    } catch (_) {
      state = const AuthSession(isAuthenticated: false, email: '');
      rethrow;
    }
  }

  Future<void> sendPasswordReset(String email) async {
    await _authService.sendPasswordResetEmail(email.trim());
  }

  Future<void> updateCurrencyCode(String currencyCode) async {
    final userId = state.uid;
    if (userId.isEmpty) throw StateError('Sign in to change your currency.');
    final previousCurrency = state.currencyCode;
    state = state.copyWith(currencyCode: currencyCode);
    try {
      await _authService.updateCurrencyCode(userId, currencyCode);
    } catch (_) {
      state = state.copyWith(currencyCode: previousCurrency);
      rethrow;
    }
  }

  @override
  void dispose() {
    unawaited(_authStateSubscription.cancel());
    super.dispose();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthSession>((ref) {
  final authService = ref.watch(firebaseAuthServiceProvider);
  return AuthNotifier(authService);
});
