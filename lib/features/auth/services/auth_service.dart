import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
      return await _loadUserProfile(user);
    } on FirebaseAuthException catch (error) {
      throw AuthServiceException(_authErrorMessage(error));
    }
  }

  Future<AppUser> signInWithGoogle() async {
    _ensureFirebaseReady();

    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        throw const AuthServiceException('Google sign-in was cancelled.');
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw const AuthServiceException(
          'Google sign-in failed. Please try again.',
        );
      }

      return await _createOrUpdateGoogleUserProfile(firebaseUser);
    } on AuthServiceException {
      rethrow;
    } on FirebaseAuthException catch (error) {
      throw AuthServiceException(_authErrorMessage(error));
    } on FirebaseException catch (error) {
      throw AuthServiceException(
        error.message ?? 'Firebase error while signing in with Google.',
      );
    } catch (_) {
      throw const AuthServiceException(
        'Google sign-in failed. Please try again.',
      );
    }
  }

  Future<void> signOut() async {
    if (!_isFirebaseReady) {
      return;
    }
    try {
      await GoogleSignIn().signOut();
    } catch (_) {
      // Firebase sign-out is the important part for app session state.
    }
    await _auth.signOut();
  }

  Future<void> sendPasswordReset(String email) async {
    _ensureFirebaseReady();
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (error) {
      throw AuthServiceException(_authErrorMessage(error));
    } on FirebaseException catch (error) {
      throw AuthServiceException(
        error.message ?? 'Firebase error while sending the reset email.',
      );
    }
  }

  Future<AppUser?> signIn({
    required String email,
    required String password,
  }) {
    return signInWithEmailAndPassword(email: email, password: password);
  }

  Future<AppUser?> currentUserProfile() async {
    if (!_isFirebaseReady) {
      return null;
    }
    final user = _auth.currentUser;
    if (user == null) {
      return null;
    }
    return _loadUserProfile(user);
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

  Future<AppUser> _createOrUpdateGoogleUserProfile(User firebaseUser) async {
    final userRef = _firestore.collection('users').doc(firebaseUser.uid);
    final snapshot = await userRef.get();
    final email = firebaseUser.email?.trim() ?? '';
    final name = _googleDisplayName(firebaseUser);
    final metadata = _googleMetadata(firebaseUser);

    if (!snapshot.exists || snapshot.data() == null) {
      final now = DateTime.now();
      final appUser = AppUser(
        uid: firebaseUser.uid,
        name: name,
        email: email,
        phone: '',
        secretPhrase: '',
        role: 'user',
        status: 'active',
        preferences: AppUser.defaultPreferences(),
        safetySettings: AppUser.defaultSafetySettings(),
        metadata: metadata,
        schemaVersion: 1,
        createdAt: now,
        updatedAt: now,
      );

      await userRef.set(appUser.toCreateMap());
      return appUser;
    }

    final data = snapshot.data()!;
    final existingMetadata = _readMetadata(data['metadata']);
    existingMetadata.addAll(metadata);

    final updates = <String, dynamic>{
      'uid': firebaseUser.uid,
      'name': name,
      'email': email,
      'role': data['role'] ?? 'user',
      'status': data['status'] ?? 'active',
      'schemaVersion': data['schemaVersion'] ?? 1,
      'preferences': data['preferences'] ?? AppUser.defaultPreferences(),
      'safetySettings':
          data['safetySettings'] ?? AppUser.defaultSafetySettings(),
      'metadata': existingMetadata,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (!data.containsKey('createdAt')) {
      updates['createdAt'] = FieldValue.serverTimestamp();
    }

    await userRef.set(updates, SetOptions(merge: true));
    return _loadUserProfile(firebaseUser);
  }

  String _googleDisplayName(User firebaseUser) {
    final displayName = firebaseUser.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }

    final email = firebaseUser.email?.trim() ?? '';
    if (email.contains('@')) {
      return email.split('@').first;
    }

    return 'Amica User';
  }

  Map<String, dynamic> _googleMetadata(User firebaseUser) {
    return {
      'authProvider': 'google',
      if (firebaseUser.photoURL != null) 'photoUrl': firebaseUser.photoURL,
    };
  }

  Map<String, dynamic> _readMetadata(dynamic value) {
    if (value is Map<String, dynamic>) {
      return Map<String, dynamic>.from(value);
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return <String, dynamic>{};
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
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
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
