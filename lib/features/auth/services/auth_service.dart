import '../models/app_user.dart';

class AuthService {
  Future<AppUser?> signIn({
    required String email,
    required String password,
  }) async {
    // TODO: Replace with Firebase Auth implementation.
    return AppUser(id: 'demo-user', email: email, displayName: 'Amica User');
  }

  Future<AppUser> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    // TODO: Create Firebase Auth account and user profile document.
    return AppUser(id: 'demo-user', email: email, displayName: displayName);
  }

  Future<void> sendPasswordReset(String email) async {
    // TODO: Trigger Firebase password reset email.
  }

  Future<void> signOut() async {
    // TODO: Sign out from Firebase Auth.
  }
}
