import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SupabaseAuthService {
  SupabaseAuthService._();
  static final SupabaseAuthService instance = SupabaseAuthService._();

  final SupabaseClient _client = Supabase.instance.client;

  /// The Web Client ID from google-services.json (client_type: 3).
  static const String _webClientId =
      '308682750622-g0gs8hg3j5gq26gi32hi2qf463399rqh.apps.googleusercontent.com';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? _webClientId : null,
    serverClientId: kIsWeb ? null : _webClientId,
  );

  User? get currentUser => _client.auth.currentUser;

  Stream<User?> get authStateChanges =>
      _client.auth.onAuthStateChange.map((data) => data.session?.user);

  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response.user;
    } catch (e) {
      debugPrint('SUPABASE AUTH SERVICE ERROR (Login): $e');
      rethrow;
    }
  }

  Future<User?> signUpWithEmailAndPassword({
    required String name,
    required String email,
    required String username,
    required String password,
    String? gender,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'username': username,
          if (gender != null) 'gender': gender,
        },
      );

      final user = response.user;
      return user;
    } catch (e) {
      debugPrint('SUPABASE AUTH SERVICE ERROR (Signup): $e');
      rethrow;
    }
  }

  /// Sign in with Google using native Google Sign-In + Supabase ID token.
  /// Returns the authenticated user or null if cancelled.
  Future<User?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled the sign-in flow
        return null;
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null) {
        throw Exception('Google Sign-In failed: No ID token received.');
      }

      final response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      final user = response.user;
      if (user != null) {
        final photoUrl = googleUser.photoUrl;
        if (photoUrl != null && photoUrl.isNotEmpty) {
          try {
            // Update auth user metadata so picture/avatar_url are saved in auth
            await _client.auth.updateUser(
              UserAttributes(
                data: {
                  'avatar_url': photoUrl,
                  'picture': photoUrl,
                },
              ),
            );
            debugPrint('Successfully updated auth user metadata with Google photoUrl: $photoUrl');
          } catch (e) {
            debugPrint('Failed to update auth user metadata: $e');
          }

          try {
            // Also try to update the public 'users' table directly in case the user already exists there
            await _client.from('users').update({
              'avatar_url': photoUrl,
            }).eq('id', user.id);
            debugPrint('Successfully updated public.users table with Google photoUrl.');
          } catch (_) {
            // Fails if the user row doesn't exist in public.users yet (first-time login),
            // which is fine since loadCurrentUser() will create it next.
          }
        }
      }

      return user;
    } catch (e) {
      debugPrint('SUPABASE AUTH SERVICE ERROR (Google Auth): $e');
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } catch (e) {
      debugPrint('SUPABASE AUTH SERVICE ERROR (Reset Password): $e');
      rethrow;
    }
  }

  Future<void> updatePassword(String newPassword) async {
    try {
      await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } catch (e) {
      debugPrint('SUPABASE AUTH SERVICE ERROR (Update Password): $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      // Sign out from Google as well
      try {
        await _googleSignIn.signOut();
      } catch (_) {}
      await _client.auth.signOut();
    } catch (e) {
      debugPrint('SUPABASE AUTH SERVICE ERROR (Sign out): $e');
    }
  }
}
