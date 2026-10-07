import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'user_service.dart';

class SupabaseAuthService {
  SupabaseAuthService._();
  static final SupabaseAuthService instance = SupabaseAuthService._();

  final SupabaseClient _client = Supabase.instance.client;

  /// The Web Client ID from Google Cloud Console.
  static const String _webClientId =
      '612128388176-p44fj4noba1f4g61urb9vgivofptvlr1.apps.googleusercontent.com';


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

  /// Sign in with Google using Supabase OAuth on Web and native Google Sign-In on Mobile.
  Future<User?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        String redirectUrl = Uri.base.origin + Uri.base.path;
        if (!redirectUrl.endsWith('/')) {
          redirectUrl = '$redirectUrl/';
        }
        await _client.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: redirectUrl,
        );
        return _client.auth.currentUser;
      }

      try {
        final googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          return null;
        }

        final googleAuth = await googleUser.authentication;
        final idToken = googleAuth.idToken;
        final accessToken = googleAuth.accessToken;

        if (idToken != null) {
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
                await UserService.instance.updateUserProfile({'avatar_url': photoUrl});
              } catch (_) {}
            }
          }
          return user;
        }
      } catch (nativeErr) {
        debugPrint('Native Google Sign-In notice ($nativeErr). Falling back to Supabase OAuth...');
        await _client.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: 'io.supabase.congrowing://login-callback',
        );
        return _client.auth.currentUser;
      }
      return null;
    } catch (e) {
      debugPrint('SUPABASE AUTH SERVICE ERROR (Google Sign-In): $e');
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
