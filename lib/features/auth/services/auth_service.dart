import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/app_user.dart';

class AuthServiceException implements Exception {
  const AuthServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthService {
  const AuthService();

  bool get _isFirebaseReady => Firebase.apps.isNotEmpty;

  FirebaseAuth get _auth => FirebaseAuth.instance;

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  Stream<AppUser?> authStateChanges() {
    if (!_isFirebaseReady) {
      return Stream<AppUser?>.value(null);
    }

    return _auth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) {
        return null;
      }
      return _loadUserProfile(firebaseUser);
    });
  }

  Future<AppUser> signUpWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String secretPhrase,
  }) async {
    _ensureFirebaseReady();

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AuthServiceException('Signup failed. Please try again.');
      }

      await user.updateDisplayName(name.trim());

      final now = DateTime.now();
      final appUser = AppUser(
        uid: user.uid,
        name: name.trim(),
        email: email.trim(),
        phone: phone.trim(),
        secretPhrase: secretPhrase.trim(),
        role: 'user',
        status: 'active',
        preferences: AppUser.defaultPreferences(),
        safetySettings: AppUser.defaultSafetySettings(),
        metadata: const {},
        schemaVersion: 1,
        createdAt: now,
        updatedAt: now,
      );

      await _firestore.collection('users').doc(user.uid).set(appUser.toCreateMap());
      return appUser;
    } on FirebaseAuthException catch (error) {
      throw AuthServiceException(_authErrorMessage(error));
    } on FirebaseException catch (error) {
      throw AuthServiceException(
        error.message ?? 'Firebase error while creating your profile.',
      );
    }
  }

  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    _ensureFirebaseReady();

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AuthServiceException('Login failed. Please try again.');
      }
      return _loadUserProfile(user);
    } on FirebaseAuthException catch (error) {
      throw AuthServiceException(_authErrorMessage(error));
    }
  }

  Future<void> signOut() async {
    if (!_isFirebaseReady) {
      return;
    }
    await _auth.signOut();
  }

  Future<void> sendPasswordReset(String email) async {
    _ensureFirebaseReady();
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (error) {
      throw AuthServiceException(_authErrorMessage(error));
    }
  }

  Future<AppUser?> signIn({
    required String email,
    required String password,
  }) {
    return signInWithEmailAndPassword(email: email, password: password);
  }

  Future<AppUser> signUp({
    required String email,
    required String password,
    required String displayName,
  }) {
    return signUpWithEmailAndPassword(
      name: displayName,
      email: email,
      password: password,
      phone: '',
      secretPhrase: '',
    );
  }

  Future<AppUser> _loadUserProfile(User firebaseUser) async {
    try {
      final snapshot = await _firestore.collection('users').doc(firebaseUser.uid).get();
      if (!snapshot.exists || snapshot.data() == null) {
        return AppUser.fallback(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          name: firebaseUser.displayName ?? 'Amica User',
        );
      }
      return AppUser.fromMap(snapshot.data()!, firebaseUser.uid);
    } on FirebaseException {
      return AppUser.fallback(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        name: firebaseUser.displayName ?? 'Amica User',
      );
    }
  }

  void _ensureFirebaseReady() {
    if (!_isFirebaseReady) {
      throw const AuthServiceException(
        'Firebase is not configured yet. Run FlutterFire CLI and add the dev Firebase config.',
      );
    }
  }

  String _authErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email or password is incorrect.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      default:
        return error.message ?? 'Authentication failed. Please try again.';
    }
  }
}
