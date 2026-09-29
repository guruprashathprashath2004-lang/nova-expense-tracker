import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';

class FirebaseAuthService {
  FirebaseAuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? _safeAuthInstance(),
        _firestore = firestore ?? _safeFirestoreInstance();

  final FirebaseAuth? _auth;
  final FirebaseFirestore? _firestore;

  bool get isAvailable => _auth != null;
  User? get currentUser => _auth?.currentUser;
  FirebaseFirestore? get firestore => _firestore;

  Stream<User?> get authStateChanges =>
      _auth?.authStateChanges() ?? const Stream.empty();

  static FirebaseAuth? _safeAuthInstance() {
    try {
      return FirebaseAuth.instance;
    } on FirebaseException {
      return null;
    }
  }

  static FirebaseFirestore? _safeFirestoreInstance() {
    try {
      return FirebaseFirestore.instance;
    } on FirebaseException {
      return null;
    }
  }

  FirebaseAuth get _requireAuth {
    final auth = _auth;
    if (auth == null) {
      throw FirebaseException(
        plugin: 'firebase_auth',
        code: 'no-app',
        message: 'Firebase has not been initialized for this app instance.',
      );
    }
    return auth;
  }

  FirebaseFirestore get _requireFirestore {
    final firestore = _firestore;
    if (firestore == null) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'no-app',
        message: 'Firebase has not been initialized for this app instance.',
      );
    }
    return firestore;
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return _requireAuth.signInWithEmailAndPassword(
        email: email, password: password);
  }

  Future<UserProfile> registerWithEmail({
    required String displayName,
    required String email,
    required String password,
  }) async {
    final credential = await _requireAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw StateError(
          'Firebase created an account without returning its user.');
    }

    final profile = UserProfile(
      uid: user.uid,
      email: email,
      displayName: displayName,
    );
    try {
      await _writeProfile(profile);
    } on FirebaseException catch (error) {
      try {
        await _requireAuth.signOut();
      } on FirebaseAuthException catch (signOutError) {
        throw StateError(
          'Your account was created, but its profile could not be saved '
          '($error), and signing out also failed ($signOutError). '
          'Please sign out manually and retry profile setup.',
        );
      }
      throw StateError(
        'Your account was created, but its profile could not be saved. '
        'You have been signed out. Please sign in again to retry profile setup. '
        'Details: $error',
      );
    }
    return profile;
  }

  Future<UserProfile> loadProfile(String uid) async {
    final snapshot = await _requireFirestore.collection('users').doc(uid).get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) {
      final user = _requireAuth.currentUser;
      if (user == null || user.uid != uid) {
        throw StateError(
          'The signed-in account is unavailable; its profile cannot be restored.',
        );
      }
      final email = user.email ?? '';
      final displayName = user.displayName?.trim().isNotEmpty == true
          ? user.displayName!.trim()
          : email.contains('@')
              ? email.substring(0, email.indexOf('@'))
              : 'Nova User';
      final profile = UserProfile(
        uid: user.uid,
        email: email,
        displayName: displayName.isEmpty ? 'Nova User' : displayName,
      );
      await _writeProfile(profile);
      return profile;
    }
    return UserProfile.fromJson(uid, data);
  }

  Future<void> _writeProfile(UserProfile profile) async {
    await _requireFirestore.collection('users').doc(profile.uid).set({
      'uid': profile.uid,
      'email': profile.email,
      'displayName': profile.displayName,
      'currencyCode': profile.currencyCode,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateCurrencyCode(String uid, String currencyCode) async {
    if (!const ['LKR', 'USD', 'EUR', 'GBP', 'INR'].contains(currencyCode)) {
      throw ArgumentError.value(currencyCode, 'currencyCode');
    }
    await _requireFirestore.collection('users').doc(uid).update({
      'currencyCode': currencyCode,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> sendPasswordResetEmail(String email) =>
      _requireAuth.sendPasswordResetEmail(email: email);

  Future<UserProfile> loadCurrentProfile() async {
    final user = currentUser;
    if (user == null) throw StateError('No authenticated user is available.');
    return loadProfile(user.uid);
  }

  Future<void> signOut() async {
    await _auth?.signOut();
  }
}

final firebaseAuthServiceProvider = Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService();
});
