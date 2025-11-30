import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';

/// Auth state for admin dashboard
enum AdminAuthState {
  initial,
  loading,
  authenticated,
  unauthenticated,
  unauthorized, // Logged in but not an admin
}

/// Admin auth state
class AdminAuthNotifier extends StateNotifier<AdminAuthState> {
  final FirebaseAuth _auth;
  User? _currentUser;

  AdminAuthNotifier({FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance,
        super(AdminAuthState.initial) {
    _init();
  }

  User? get currentUser => _currentUser;

  void _init() {
    _auth.authStateChanges().listen((user) {
      _currentUser = user;
      if (user == null) {
        state = AdminAuthState.unauthenticated;
      } else if (_isAdmin(user.email)) {
        state = AdminAuthState.authenticated;
      } else {
        state = AdminAuthState.unauthorized;
      }
    });
  }

  bool _isAdmin(String? email) {
    if (email == null) return false;
    return AdminConstants.adminEmails.contains(email.toLowerCase());
  }

  Future<void> signInWithGoogle() async {
    try {
      state = AdminAuthState.loading;

      final googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');

      await _auth.signInWithPopup(googleProvider);
      // State will be updated by authStateChanges listener
    } catch (e) {
      state = AdminAuthState.unauthenticated;
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    state = AdminAuthState.unauthenticated;
  }
}

/// Provider for admin auth state
final adminAuthProvider =
    StateNotifierProvider<AdminAuthNotifier, AdminAuthState>((ref) {
  return AdminAuthNotifier();
});

/// Provider for current user
final currentUserProvider = Provider<User?>((ref) {
  final authNotifier = ref.watch(adminAuthProvider.notifier);
  return authNotifier.currentUser;
});
