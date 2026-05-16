import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/config/get_it_config.dart';
import '../states/auth_state.dart';
import '../../domain/entities/user_entity.dart';
import '../../data/models/user_model.dart';
import '../../../../core/utils/logger.dart';

class AuthController extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthController(this._authService) : super(const AuthInitial()) {
    _initializeAuthState();
  }

  /// While > 0, [authStateChanges] listener must not overwrite UI state — avoids
  /// races where the stream sets [AuthUnauthenticated] during Google/email sign-in.
  int _authUiOperationDepth = 0;

  // Helper method to extract clean error messages without Exception prefix
  String _extractErrorMessage(dynamic error) {
    String errorMessage = error.toString();
    if (errorMessage.startsWith('Exception: ')) {
      return errorMessage.substring(11);
    }
    return errorMessage;
  }


  // Initialize auth state by listening to auth changes
  void _initializeAuthState() {
    _authService.authStateChanges.listen((User? user) async {
      if (user == null) {
        await _clearAllLocalDataOnAuthChange();
        state = const AuthUnauthenticated();
        return;
      }
      if (_authUiOperationDepth > 0) {
        Logger.info(
          'AuthController: Skipping authStateChanges sync while auth UI operation is in flight',
        );
        return;
      }
      try {
        // Retry logic for loading user profile
        UserModel? userProfile;
        int retryCount = 0;
        const int maxRetries = 5;

        while (userProfile == null && retryCount < maxRetries) {
          try {
            userProfile = await _authService.getUserProfile(user.uid);
            if (userProfile != null) {
              break;
            }
          } catch (e) {
            Logger.info(
              '⚠️ AuthController: Profile load attempt ${retryCount + 1} failed: $e',
            );
          }

          retryCount++;
          if (retryCount < maxRetries) {
            await Future<void>.delayed(Duration(milliseconds: 400 * retryCount));
          }
        }

        if (userProfile != null) {
          state = AuthAuthenticated(userProfile.toEntity());
        } else {
          Logger.info(
            '⚠️ AuthController: No Firestore profile yet — using Firebase user fallback',
          );
          state = AuthAuthenticated(
            _authService.buildSessionUserModelFromFirebaseUser(user).toEntity(),
          );
        }
      } catch (e) {
        Logger.info('❌ AuthController: Error in auth state change: $e');
        state = AuthError('Failed to load user profile: $e');
      }
    });
  }

  // Clear all local data when authentication state changes
  Future<void> _clearAllLocalDataOnAuthChange() async {
    try {
      // Clear SharedPreferences directly to avoid dependency issues
      // This is safer than trying to inject the repository
      final prefs = await SharedPreferences.getInstance();

      // Clear test results
      await prefs.remove('test_result_history');

      // Clear sync queue
      await prefs.remove('sync_queue');

      // Clear last sync timestamp
      await prefs.remove('last_firestore_sync');

      Logger.info(
        '✅ AuthController: All local data cleared on auth state change',
      );
    } catch (e) {
      Logger.info(
        '❌ AuthController: Failed to clear local data on auth change: $e',
      );
      // Don't throw error, auth state change should still proceed
    }
  }

  // Sign in with email and password - OPTIMIZED
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    _authUiOperationDepth++;
    state = const AuthLoading();
    try {
      final UserCredential? result = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result?.user != null) {
        final UserModel? userProfile = await _authService.getUserProfile(
          result!.user!.uid,
        );
        if (userProfile != null) {
          NotificationService.showLoginSuccess(
            username: userProfile.username,
          );
          state = AuthAuthenticated(userProfile.toEntity());
        } else {
          state = AuthAuthenticated(
            _authService.buildSessionUserModelFromFirebaseUser(result.user!).toEntity(),
          );
        }
      } else {
        state = const AuthError('Sign-in failed. Please try again.');
      }
    } catch (e) {
      final String errorMessage = _extractErrorMessage(e);
      state = AuthError(errorMessage);
    } finally {
      _authUiOperationDepth--;
    }
  }

  // Create user with email and password - OPTIMIZED
  Future<void> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String username,
  }) async {
    _authUiOperationDepth++;
    state = const AuthLoading();
    try {
      Logger.info('🔧 AuthController: Starting user registration');
      final UserCredential? result = await _authService.createUserWithEmailAndPassword(
        email: email,
        password: password,
        username: username,
      );

      if (result?.user != null) {
        UserModel? userProfile = await _authService.getUserProfile(result!.user!.uid);
        userProfile ??= _authService.buildSessionUserModelFromFirebaseUser(result.user!);
        NotificationService.showRegistrationSuccess(
          username: userProfile.username,
        );
        state = AuthAuthenticated(userProfile.toEntity());
      } else {
        state = const AuthError('Unable to create account. Please try again.');
      }
    } catch (e, stackTrace) {
      Logger.info('❌ AuthController: Error during registration: $e');
      Logger.info('❌ AuthController: Stack trace: $stackTrace');
      NotificationService.showError(
        title: '❌ Registration Failed',
        message: 'Unable to create account. Please try again.',
      );
      final String errorMessage = _extractErrorMessage(e);
      state = AuthError(errorMessage);
    } finally {
      _authUiOperationDepth--;
    }
  }

  // Sign in with Google - OPTIMIZED
  Future<void> signInWithGoogle() async {
    _authUiOperationDepth++;
    state = const AuthLoading();
    try {
      Logger.info('🔧 AuthController: Starting Google Sign-In');
      final UserCredential? result = await _authService.signInWithGoogle();

      if (result?.user == null) {
        Logger.info('⚠️ AuthController: User canceled Google Sign-In');
        state = const AuthUnauthenticated();
      } else {
        final User firebaseUser = result!.user!;
        Logger.info('✅ AuthController: Google Sign-In successful for ${firebaseUser.uid}');

        UserModel? userProfile;
        const int maxRetries = 5;
        for (int attempt = 0; attempt < maxRetries; attempt++) {
          try {
            userProfile = await _authService.getUserProfile(firebaseUser.uid);
            if (userProfile != null) {
              break;
            }
          } catch (e) {
            Logger.info('⚠️ AuthController: Profile attempt ${attempt + 1} failed: $e');
          }
          await Future<void>.delayed(Duration(milliseconds: 350 * (attempt + 1)));
        }

        final UserModel resolvedProfile =
            userProfile ?? _authService.buildSessionUserModelFromFirebaseUser(firebaseUser);
        NotificationService.showSuccess(
          title: '🚀 Google Sign-In Success',
          message: 'Welcome ${resolvedProfile.username}! Ready to continue testing?',
        );
        state = AuthAuthenticated(resolvedProfile.toEntity());
      }
    } catch (e) {
      Logger.info('❌ AuthController: Google Sign-In error: $e');
      final String errorMessage = _extractErrorMessage(e);
      state = AuthError('Google Sign-In failed: $errorMessage');
    } finally {
      _authUiOperationDepth--;
    }
  }

  // Sign out
  Future<void> signOut() async {
    _authUiOperationDepth++;
    state = const AuthLoading();
    try {
      await _authService.signOut();
      state = const AuthUnauthenticated();
    } catch (e) {
      final String errorMessage = _extractErrorMessage(e);
      state = AuthError(errorMessage);
    } finally {
      _authUiOperationDepth--;
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    _authUiOperationDepth++;
    state = const AuthLoading();
    try {
      await _authService.sendPasswordResetEmail(email);
      state = const AuthSuccess(
        '📧 Password reset email sent! Check your inbox.',
      );
    } catch (e) {
      final String errorMessage = _extractErrorMessage(e);
      state = AuthError(errorMessage);
    } finally {
      _authUiOperationDepth--;
    }
  }

  // Clear error state
  void clearError() {
    if (state is AuthError || state is AuthSuccess) {
      state = const AuthUnauthenticated();
    }
  }

  // Show temporary success message then return to authenticated state
  void showSuccessMessage(String message, UserEntity user) async {
    state = AuthSuccess(message);
    // Brief success message display
    await Future.delayed(const Duration(milliseconds: 800));
    state = AuthAuthenticated(user);
  }
}

// Provider for AuthController
final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    return AuthController(getIt<AuthService>());
  },
);
