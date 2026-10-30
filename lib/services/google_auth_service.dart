// ignore_for_file: avoid_print

import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'auth_service.dart';
import '../schemas/auth_schemas.dart';

class GoogleAuthService {
  // Initialize GoogleSignIn
  // Web requires a separate client ID; mobile detects it from the configuration
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],

    clientId: kIsWeb
        ? 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com' // Replace this value
        : null, // Detected automatically on mobile
  );

  final AuthService _authService = AuthService();

  /// Sign in with Google and send the information to the backend
  Future<TokenResponse> signInWithGoogle() async {
    try {
      // 0. Sign out first so the user can choose another account
      // Do not use the cached account
      await _googleSignIn.signOut();

      // 1. Trigger Google Sign In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        throw Exception('Google Sign-In cancelled by user');
      }

      // 2. Get authentication information
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // 3. Get the ID token (optional; only needed for verification)
      final String? idToken = googleAuth.idToken;
      final String? accessToken = googleAuth.accessToken;

      print('🔑 ID Token: ${idToken != null ? "✅ Available" : "❌ Null"}');
      print(
        '🔑 Access Token: ${accessToken != null ? "✅ Available" : "❌ Null"}',
      );

      // The ID token may be null on some platforms or configurations.
      // User information can still be obtained from GoogleSignInAccount.
      if (idToken == null && accessToken == null) {
        throw Exception(
          'Failed to get Google authentication tokens. '
          'Please check:\n'
          '1. Has the SHA-1 fingerprint been added to Google Cloud Console?\n'
          '2. Has the OAuth consent screen been configured?\n'
          '3. Wait 5–10 minutes after completing the configuration.\n'
          'Run: cd android && gradlew signingReport',
        );
      }

      // 4. Parse user information
      final String email = googleUser.email;
      final String? name = googleUser.displayName;
      final String? avatarUrl = googleUser.photoUrl;
      final String sub = googleUser.id; // Google User ID

      print('📧 Google User: $email');
      print('👤 Name: $name');
      print('🆔 Google ID (sub): $sub');

      // 5. Send the information to the backend to create or log in the user
      final tokenResponse = await _authService.loginWithGoogle(
        email: email,
        name: name ?? email.split('@')[0],
        sub: sub,
        avatarUrl: avatarUrl,
      );

      print('✅ Google Login successful!');
      return tokenResponse;
    } catch (e) {
      print('❌ Google Sign-In error: $e');
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _authService.logout();
  }

  /// Check if user is currently signed in with Google
  Future<bool> isSignedIn() async {
    return await _googleSignIn.isSignedIn();
  }

  /// Get current Google user (if signed in)
  Future<GoogleSignInAccount?> getCurrentUser() async {
    return _googleSignIn.currentUser;
  }
}
