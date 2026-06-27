import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State holder for admin auth.
class AdminAuthState {
  final User? user;
  final bool isAdmin;
  final bool initialized;
  final String? errorMessage;

  const AdminAuthState({
    this.user,
    this.isAdmin = false,
    this.initialized = false,
    this.errorMessage,
  });

  bool get isAuthenticated => initialized && user != null && isAdmin;

  AdminAuthState copyWith({
    User? user,
    bool? isAdmin,
    bool? initialized,
    String? errorMessage,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AdminAuthState(
      user: clearUser ? null : (user ?? this.user),
      isAdmin: isAdmin ?? this.isAdmin,
      initialized: initialized ?? this.initialized,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Riverpod controller for admin auth state and sign-in/out actions.
class AdminAuthController extends Notifier<AdminAuthState> {
  StreamSubscription<User?>? _authSub;

  @override
  AdminAuthState build() {
    _authSub = FirebaseAuth.instance.authStateChanges().listen(_handleUser);
    ref.onDispose(() => _authSub?.cancel());
    return const AdminAuthState();
  }

  Future<void> _handleUser(User? user) async {
    if (user == null) {
      // Preserve last error (e.g. "not an admin") across the post-signOut emit
      state = AdminAuthState(
        initialized: true,
        errorMessage: state.errorMessage,
      );
      return;
    }

    try {
      // Force token refresh so newly-granted claims are seen
      final token = await user.getIdTokenResult(true);
      final isAdmin = token.claims?['admin'] == true;

      if (!isAdmin) {
        // Authenticated but not an admin — sign them out, show message
        state = const AdminAuthState(
          initialized: true,
          errorMessage:
          'This account is not authorized for admin access.',
        );
        await FirebaseAuth.instance.signOut();
        return;
      }

      state = AdminAuthState(
        user: user,
        isAdmin: true,
        initialized: true,
      );
    } catch (e) {
      state = AdminAuthState(
        initialized: true,
        errorMessage: 'Auth verification failed: $e',
      );
      await FirebaseAuth.instance.signOut();
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  Future<void> signInWithEmail(String email, String password) async {
    clearError();
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        errorMessage: _mapAuthError(e),
        initialized: true,
      );
      rethrow;
    }
  }

  Future<void> signInWithGoogle() async {
    clearError();
    try {
      final provider = GoogleAuthProvider();
      await FirebaseAuth.instance.signInWithPopup(provider);
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        errorMessage: _mapAuthError(e),
        initialized: true,
      );
      rethrow;
    }
  }

  Future<void> signOut() async {
    clearError();
    await FirebaseAuth.instance.signOut();
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      case 'popup-closed-by-user':
        return 'Sign-in cancelled.';
      default:
        return e.message ?? 'Sign-in failed.';
    }
  }
}

final adminAuthProvider =
NotifierProvider<AdminAuthController, AdminAuthState>(
  AdminAuthController.new,
);