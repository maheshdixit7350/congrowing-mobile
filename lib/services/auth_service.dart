// Legacy AuthService - now delegates to FirebaseAuthService for Google sign-in.
// Kept for backward compatibility if any file still references it.
import 'package:flutter/material.dart';
import 'supabase_auth_service.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  Future<void> signInWithGoogle() async {
    try {
      await SupabaseAuthService.instance.signInWithGoogle();
    } catch (e) {
      debugPrint('AUTH SERVICE ERROR (Google Sign-In): $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await SupabaseAuthService.instance.signOut();
  }
}
