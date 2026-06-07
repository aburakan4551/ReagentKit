import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:reagentkit/core/services/firestore_service.dart';
import 'package:reagentkit/core/theme/app_colors.dart';
import 'package:reagentkit/core/utils/layout_helper.dart';
import 'package:reagentkit/core/widgets/adaptive_section_title.dart';
import 'package:reagentkit/core/widgets/adaptive_text_field.dart';
import 'package:reagentkit/core/widgets/gradient_action_button.dart';
import 'package:reagentkit/features/premium/presentation/screens/paywall_screen.dart';
import 'package:reagentkit/core/services/premium_service.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/states/auth_state.dart';
import '../../../../core/services/notification_service.dart';

import '../../../reagent_testing/presentation/providers/reagent_testing_providers.dart';
import '../../../reagent_testing/presentation/states/test_result_history_state.dart';
import '../../../reagent_testing/domain/entities/test_result_entity.dart';
import '../../../../l10n/app_localizations.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool _isLoginMode = true;
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _usernameController = TextEditingController();

  // Password visibility
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _toggleAuthMode() {
    setState(() {
      _isLoginMode = !_isLoginMode;
      _formKey.currentState?.reset();
      _emailController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
      _usernameController.clear();
    });
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    final authController = ref.read(authControllerProvider.notifier);

    if (_isLoginMode) {
      authController.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } else {
      authController.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        username: _usernameController.text.trim(),
      );
    }
  }

  void _signInWithGoogle() {
    final authController = ref.read(authControllerProvider.notifier);
    authController.signInWithGoogle();
  }

  void _signOut() {
    final authController = ref.read(authControllerProvider.notifier);
    authController.signOut();
    _clearTextFields();
  }

  bool _isArabic() {
    return Localizations.localeOf(context).languageCode == 'ar';
  }

  Widget _buildAccountManagementCard(dynamic user, ThemeData theme, AppLocalizations l10n) {
    final isDarkMode = theme.brightness == Brightness.dark;
    final ar = _isArabic();
    
    // Check if the user is signed in with email/password
    final currentUser = FirebaseAuth.instance.currentUser;
    final providerId = currentUser?.providerData.isNotEmpty == true
        ? currentUser!.providerData.first.providerId
        : 'password';
    final isEmailProvider = providerId == 'password';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdaptiveSectionTitle(
          title: ar ? 'إدارة الحساب' : 'Account Management',
          showAccentBar: true,
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: isDarkMode ? AppColors.surfaceBase : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDarkMode ? AppColors.borderSubtle : AppColors.lightBorderSubtle,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Edit Profile (Display Name)
              ListTile(
                leading: const Icon(HeroIcons.pencil_square, color: Colors.blue),
                title: Text(
                  ar ? 'تعديل الملف الشخصي' : 'Edit Profile',
                  style: TextStyle(color: isDarkMode ? Colors.white : AppColors.lightTextPrimary),
                ),
                subtitle: Text(
                  ar ? 'تغيير الاسم المستعار' : 'Change display name',
                  style: TextStyle(color: isDarkMode ? AppColors.textSecondary : AppColors.lightTextSecondary, fontSize: 12),
                ),
                trailing: const Icon(HeroIcons.chevron_right, size: 16),
                onTap: () => _showEditNameDialog(user),
              ),
              const Divider(height: 1),
              
              // Change Password (only for Email provider)
              if (isEmailProvider) ...[
                ListTile(
                  leading: const Icon(HeroIcons.key, color: Colors.amber),
                  title: Text(
                    ar ? 'تغيير كلمة المرور' : 'Change Password',
                    style: TextStyle(color: isDarkMode ? Colors.white : AppColors.lightTextPrimary),
                  ),
                  subtitle: Text(
                    ar ? 'تحديث بيانات الأمان الخاصة بك' : 'Update your security credentials',
                    style: TextStyle(color: isDarkMode ? AppColors.textSecondary : AppColors.lightTextSecondary, fontSize: 12),
                  ),
                  trailing: const Icon(HeroIcons.chevron_right, size: 16),
                  onTap: _showChangePasswordDialog,
                ),
                const Divider(height: 1),
              ],
              
              // Logout
              ListTile(
                leading: Icon(HeroIcons.arrow_right_on_rectangle, color: theme.colorScheme.primary),
                title: Text(
                  l10n.signOut,
                  style: TextStyle(color: isDarkMode ? Colors.white : AppColors.lightTextPrimary),
                ),
                subtitle: Text(
                  ar ? 'الخروج من الجلسة الحالية' : 'Exit current session',
                  style: TextStyle(color: isDarkMode ? AppColors.textSecondary : AppColors.lightTextSecondary, fontSize: 12),
                ),
                trailing: const Icon(HeroIcons.chevron_right, size: 16),
                onTap: _signOut,
              ),
              const Divider(height: 1),
              
              // Delete Account
              ListTile(
                leading: const Icon(HeroIcons.trash, color: Colors.red),
                title: Text(
                  ar ? 'حذف الحساب' : 'Delete Account',
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  ar ? 'حذف حسابك وبياناتك نهائياً' : 'Permanently delete your account and data',
                  style: TextStyle(color: Colors.red.withOpacity(0.7), fontSize: 12),
                ),
                trailing: const Icon(HeroIcons.chevron_right, size: 16, color: Colors.red),
                onTap: () => _showDeleteAccountWorkflow(user),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showEditNameDialog(dynamic user) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final ar = _isArabic();
    final controller = TextEditingController(text: user.displayName ?? user.username);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? AppColors.surfaceBase : Colors.white,
          title: Text(
            ar ? 'تعديل الملف الشخصي' : 'Edit Profile',
            style: TextStyle(color: isDarkMode ? Colors.white : AppColors.lightTextPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AdaptiveTextField(
                controller: controller,
                labelText: ar ? 'الاسم المستعار' : 'Display Name',
                hintText: ar ? 'أدخل الاسم الجديد' : 'Enter new name',
                prefixIcon: const Icon(HeroIcons.user),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel, style: TextStyle(color: theme.colorScheme.primary)),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = controller.text.trim();
                if (newName.isNotEmpty) {
                  try {
                    await FirebaseAuth.instance.currentUser?.updateDisplayName(newName);
                    await FirestoreService().updateUserProfile(
                      user.uid,
                      {'displayName': newName},
                    );
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      NotificationService.showSuccess(
                        title: ar ? 'نجاح' : 'Success',
                        message: ar ? 'تم تحديث الملف الشخصي بنجاح' : 'Profile updated successfully',
                      );
                    }
                  } catch (e) {
                    NotificationService.showError(
                      title: ar ? 'خطأ' : 'Error',
                      message: e.toString(),
                    );
                  }
                }
              },
              child: Text(ar ? 'حفظ' : 'Save'),
            ),
          ],
        );
      },
    );
  }

  void _showChangePasswordDialog() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final ar = _isArabic();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? AppColors.surfaceBase : Colors.white,
          title: Text(
            ar ? 'تغيير كلمة المرور' : 'Change Password',
            style: TextStyle(color: isDarkMode ? Colors.white : AppColors.lightTextPrimary),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AdaptiveTextField(
                  controller: newPasswordController,
                  labelText: ar ? 'كلمة المرور الجديدة' : 'New Password',
                  hintText: 'Minimum 6 characters',
                  obscureText: true,
                  prefixIcon: const Icon(HeroIcons.lock_closed),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.pleaseEnterPassword;
                    }
                    if (value.length < 6) {
                      return l10n.passwordMinLength;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AdaptiveTextField(
                  controller: confirmPasswordController,
                  labelText: l10n.confirmPassword,
                  hintText: 'Confirm new password',
                  obscureText: true,
                  prefixIcon: const Icon(HeroIcons.lock_closed),
                  validator: (value) {
                    if (value != newPasswordController.text) {
                      return l10n.passwordsDoNotMatch;
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel, style: TextStyle(color: theme.colorScheme.primary)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  try {
                    await FirebaseAuth.instance.currentUser?.updatePassword(newPasswordController.text);
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      NotificationService.showSuccess(
                        title: ar ? 'نجاح' : 'Success',
                        message: ar ? 'تم تغيير كلمة المرور بنجاح' : 'Password changed successfully',
                      );
                    }
                  } catch (e) {
                    NotificationService.showError(
                      title: ar ? 'خطأ' : 'Error',
                      message: e.toString(),
                    );
                  }
                }
              },
              child: Text(ar ? 'حفظ' : 'Save'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteAccountWorkflow(dynamic user) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final ar = _isArabic();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? AppColors.surfaceBase : Colors.white,
          title: Row(
            children: [
              const Icon(HeroIcons.exclamation_triangle, color: Colors.red),
              const SizedBox(width: 8),
              Text(
                ar ? 'حذف الحساب' : 'Delete Account',
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ),
          content: Text(
            ar ? 'تحذير: هذا الإجراء دائم ولا يمكن التراجع عنه. سيتم حذف جميع بيانات ملفك الشخصي وتاريخ الاختبارات نهائياً.' : 'Warning: This action is permanent and cannot be undone. All your profile, test history, and data will be permanently deleted.',
            style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel, style: TextStyle(color: theme.colorScheme.primary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _triggerReauthenticationFlow(user);
              },
              child: Text(ar ? 'حذف' : 'Delete'),
            ),
          ],
        );
      },
    );
  }

  void _triggerReauthenticationFlow(dynamic user) async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final ar = _isArabic();

    // Get primary provider ID
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final providerId = currentUser.providerData.isNotEmpty
        ? currentUser.providerData.first.providerId
        : 'password';

    if (providerId == 'password') {
      final passwordController = TextEditingController();
      final formKey = GlobalKey<FormState>();

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: isDarkMode ? AppColors.surfaceBase : Colors.white,
            title: Text(
              ar ? 'مطلوب إعادة المصادقة' : 'Re-authentication Required',
              style: TextStyle(color: isDarkMode ? Colors.white : AppColors.lightTextPrimary),
            ),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    ar ? 'الرجاء إدخال كلمة المرور الحالية للتحقق من هويتك قبل حذف الحساب.' : 'Please enter your current password to verify identity before deleting your account.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  AdaptiveTextField(
                    controller: passwordController,
                    labelText: l10n.password,
                    obscureText: true,
                    prefixIcon: const Icon(HeroIcons.lock_closed),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.pleaseEnterPassword;
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.cancel, style: TextStyle(color: theme.colorScheme.primary)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  if (formKey.currentState?.validate() ?? false) {
                    Navigator.of(context).pop();
                    final success = await ref
                        .read(authControllerProvider.notifier)
                        .reauthenticateWithEmail(passwordController.text);
                    if (success) {
                      await ref.read(authControllerProvider.notifier).deleteAccount();
                    }
                  }
                },
                child: Text(ar ? 'تأكيد' : 'Confirm'),
              ),
            ],
          );
        },
      );
    } else if (providerId == 'google.com') {
      NotificationService.showInfo(
        title: ar ? 'إعادة المصادقة' : 'Re-authentication',
        message: ar ? 'جاري تشغيل تسجيل الدخول بـ Google للتحقق من هويتك...' : 'Launching Google Sign-In to verify your identity...',
      );
      final success = await ref
          .read(authControllerProvider.notifier)
          .reauthenticateWithGoogle();
      if (success) {
        await ref.read(authControllerProvider.notifier).deleteAccount();
      }
    } else if (providerId == 'apple.com') {
      NotificationService.showInfo(
        title: ar ? 'إعادة المصادقة' : 'Re-authentication',
        message: ar ? 'جاري تشغيل تسجيل الدخول بـ Apple للتحقق من هويتك...' : 'Launching Apple Sign-In to verify your identity...',
      );
      final success = await ref
          .read(authControllerProvider.notifier)
          .reauthenticateWithApple();
      if (success) {
        await ref.read(authControllerProvider.notifier).deleteAccount();
      }
    } else {
      // Fallback: try direct delete
      await ref.read(authControllerProvider.notifier).deleteAccount();
    }
  }

  void _clearTextFields() {
    _emailController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
    _usernameController.clear();

    // Reset form validation state
    _formKey.currentState?.reset();

    // Reset password visibility states
    setState(() {
      _isPasswordVisible = false;
      _isConfirmPasswordVisible = false;
    });
  }

  void _showPasswordResetDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final resetEmailController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final theme = Theme.of(context);
          final isDarkMode = theme.brightness == Brightness.dark;
          
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: isDarkMode ? AppColors.surfaceBase : AppColors.lightSurfaceBase,
            title: Row(
              children: [
                Icon(Icons.lock_reset, color: theme.colorScheme.primary, size: 24),
                const SizedBox(width: 12),
                Text(
                  l10n.resetPasswordTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 320,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.resetPasswordDescription,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? AppColors.textSecondary : AppColors.lightTextSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Security Notice
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.security,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Reset links expire in 1 hour and can only be used once for security.',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDarkMode ? AppColors.textSecondary : AppColors.lightTextSecondary,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  AdaptiveTextField(
                    controller: resetEmailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    labelText: l10n.email,
                    hintText: l10n.enterEmailToReset,
                    prefixIcon: Icon(HeroIcons.envelope, color: theme.colorScheme.primary.withOpacity(0.7)),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.pleaseEnterEmail;
                      }
                      if (!RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      ).hasMatch(value)) {
                        return l10n.pleaseEnterValidEmail;
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                child: Text(
                  l10n.backToLogin,
                  style: TextStyle(
                    color: isDarkMode ? AppColors.textMuted : AppColors.lightTextMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        final email = resetEmailController.text.trim();
                        if (email.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.pleaseEnterEmail),
                              backgroundColor: AppColors.statusError,
                            ),
                          );
                          return;
                        }

                        setState(() {
                          isLoading = true;
                        });

                        try {
                          await ref
                              .read(authControllerProvider.notifier)
                              .sendPasswordResetEmail(email);

                          if (context.mounted) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.passwordResetEmailSent),
                                backgroundColor: AppColors.statusSuccess,
                                duration: const Duration(seconds: 4),
                              ),
                            );
                          }
                        } catch (e) {
                          setState(() {
                            isLoading = false;
                          });
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: ${e.toString()}'),
                                backgroundColor: AppColors.statusError,
                              ),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(l10n.sendResetEmail),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final historyState = ref.watch(testResultHistoryControllerProvider);
    final premiumService = ref.watch(premiumServiceProvider);
    final theme = Theme.of(context);

    // Show notifications for errors and success messages
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (authState is AuthError) {
        NotificationService.showError(message: authState.message);
      } else if (authState is AuthSuccess) {
        NotificationService.showSuccess(message: authState.message);
      }
    });

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: _buildModernAppBar(authState, theme),
      body: _buildBody(authState, historyState, premiumService, theme),
    );
  }

  PreferredSizeWidget _buildModernAppBar(AuthState authState, ThemeData theme) {
    final isDarkMode = theme.brightness == Brightness.dark;
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Icon(HeroIcons.user, color: theme.colorScheme.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Text(
            _getAppBarTitle(authState),
            style: theme.textTheme.titleLarge?.copyWith(
              color: isDarkMode ? Colors.white : AppColors.lightTextPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: const [],
    );
  }

  String _getAppBarTitle(AuthState authState) {
    final l10n = AppLocalizations.of(context)!;
    if (authState is AuthAuthenticated) {
      return l10n.laboratoryProfile;
    }
    return _isLoginMode ? l10n.labAccess : l10n.joinLaboratory;
  }

  Widget _buildBody(
    AuthState authState,
    TestResultHistoryState historyState,
    PremiumService premiumService,
    ThemeData theme,
  ) {
    final l10n = AppLocalizations.of(context)!;
    if (authState is AuthAuthenticated) {
      return _buildModernProfileView(authState.user, historyState, premiumService, theme);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildModernWelcomeSection(l10n, theme),
          const SizedBox(height: 24),
          _buildModernAuthForm(authState, l10n, theme),
          const SizedBox(height: 20),
          _buildModernGoogleSignInButton(authState, l10n, theme),
          if (!kIsWeb && Platform.isIOS) ...[
            const SizedBox(height: 12),
            _buildModernAppleSignInButton(authState, l10n, theme),
          ],
          const SizedBox(height: 20),
          _buildToggleAuthModeButton(l10n, theme),
          SizedBox(height: LayoutHelper.getBottomNavPadding(context)),
        ],
      ),
    );
  }

  Widget _buildModernProfileView(
    user,
    TestResultHistoryState historyState,
    PremiumService premiumService,
    ThemeData theme,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final List<TestResultEntity> results = historyState.maybeWhen(
      loaded: (res) => res,
      orElse: () => [],
    );

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileHeaderCard(
            user: user,
            totalTests: results.length,
            isPremium: premiumService.isPremium,
            freeScansLeft: premiumService.freeScansLeft,
            onUpgradePressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PaywallScreen()),
              );
            },
          ),
          const SizedBox(height: 24),
          ActivityCard(results: results),
          const SizedBox(height: 24),
          const SafetyReminderCard(),
          const SizedBox(height: 24),
          AccountInfoCard(user: user),
          const SizedBox(height: 24),
          _buildAccountManagementCard(user, theme, l10n),
          SizedBox(height: LayoutHelper.getBottomNavPadding(context)),
        ],
      ),
    );
  }

  Widget _buildModernWelcomeSection(AppLocalizations l10n, ThemeData theme) {
    final isDarkMode = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceBase : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDarkMode ? AppColors.borderSubtle : AppColors.lightBorderSubtle,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isLoginMode ? HeroIcons.beaker : HeroIcons.user_plus,
              size: 40,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _isLoginMode ? l10n.welcomeBack : l10n.joinOurLab,
            style: theme.textTheme.titleLarge?.copyWith(
              color: isDarkMode ? Colors.white : AppColors.lightTextPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isLoginMode ? l10n.accessYourLab : l10n.startYourJourney,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDarkMode ? AppColors.textSecondary : AppColors.lightTextSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildModernAuthForm(
    AuthState authState,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    final isLoading = authState is AuthLoading;
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceBase : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDarkMode ? AppColors.borderSubtle : AppColors.lightBorderSubtle,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_isLoginMode) ...[
              AdaptiveTextField(
                controller: _usernameController,
                labelText: l10n.username,
                prefixIcon: Icon(HeroIcons.user, color: theme.colorScheme.primary.withOpacity(0.7)),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.pleaseEnterUsername;
                  }
                  if (value.trim().length < 3) {
                    return l10n.usernameMinLength;
                  }
                  if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value.trim())) {
                    return l10n.usernameInvalidChars;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
            ],
            AdaptiveTextField(
              controller: _emailController,
              labelText: l10n.emailAddress,
              prefixIcon: Icon(HeroIcons.envelope, color: theme.colorScheme.primary.withOpacity(0.7)),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.pleaseEnterEmail;
                }
                if (!RegExp(
                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                ).hasMatch(value.trim())) {
                  return l10n.pleaseEnterValidEmail;
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            AdaptiveTextField(
              controller: _passwordController,
              labelText: l10n.password,
              prefixIcon: Icon(HeroIcons.lock_closed, color: theme.colorScheme.primary.withOpacity(0.7)),
              obscureText: !_isPasswordVisible,
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? HeroIcons.eye_slash : HeroIcons.eye,
                  color: isDarkMode ? AppColors.textMuted : AppColors.lightTextMuted,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.pleaseEnterPassword;
                }
                if (!_isLoginMode && value.length < 6) {
                  return l10n.passwordMinLength;
                }
                return null;
              },
            ),
            if (!_isLoginMode) ...[
              const SizedBox(height: 20),
              AdaptiveTextField(
                controller: _confirmPasswordController,
                labelText: l10n.confirmPassword,
                prefixIcon: Icon(HeroIcons.lock_closed, color: theme.colorScheme.primary.withOpacity(0.7)),
                obscureText: !_isConfirmPasswordVisible,
                suffixIcon: IconButton(
                  icon: Icon(
                    _isConfirmPasswordVisible ? HeroIcons.eye_slash : HeroIcons.eye,
                    color: isDarkMode ? AppColors.textMuted : AppColors.lightTextMuted,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                    });
                  },
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.pleaseConfirmPassword;
                  }
                  if (value != _passwordController.text) {
                    return l10n.passwordsDoNotMatch;
                  }
                  return null;
                },
              ),
            ],
            if (_isLoginMode) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _showPasswordResetDialog(context),
                  child: Text(
                    l10n.forgotPassword,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            GradientActionButton(
              onPressed: isLoading ? null : _submitForm,
              text: _isLoginMode
                  ? (isLoading ? l10n.signingIn : l10n.accessLaboratory)
                  : (isLoading ? l10n.creatingAccount : l10n.joinLaboratory),
              isLoading: isLoading,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernGoogleSignInButton(
    AuthState authState,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    final isLoading = authState is AuthLoading;
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceBase : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDarkMode ? AppColors.borderSubtle : AppColors.lightBorderSubtle,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 1,
                  color: isDarkMode ? AppColors.borderSubtle : AppColors.lightBorderSubtle,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  l10n.orContinueWith,
                  style: TextStyle(
                    color: isDarkMode ? AppColors.textMuted : AppColors.lightTextMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 1,
                  color: isDarkMode ? AppColors.borderSubtle : AppColors.lightBorderSubtle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 56,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(
                color: isDarkMode ? AppColors.borderSubtle : AppColors.lightBorderHighlight,
              ),
              borderRadius: BorderRadius.circular(16),
              color: isDarkMode ? AppColors.surfaceElevated : AppColors.lightBackgroundBase,
            ),
            child: TextButton.icon(
              onPressed: isLoading ? null : _signInWithGoogle,
              icon: Image.asset(
                'assets/images/google_logo.png',
                height: 22,
                width: 22,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    HeroIcons.globe_americas,
                    size: 22,
                    color: Color(0xFF4285F4),
                  );
                },
              ),
              label: Text(
                _isLoginMode ? l10n.signInWithGoogle : l10n.signUpWithGoogle,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : AppColors.lightTextPrimary,
                ),
              ),
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernAppleSignInButton(
    AuthState authState,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    final isLoading = authState is AuthLoading;

    return SignInWithAppleButton(
      onPressed: isLoading
          ? null
          : () {
              ref.read(authControllerProvider.notifier).signInWithApple();
            },
      style: theme.brightness == Brightness.dark
          ? SignInWithAppleButtonStyle.white
          : SignInWithAppleButtonStyle.black,
      borderRadius: BorderRadius.circular(16),
    );
  }

  Widget _buildToggleAuthModeButton(AppLocalizations l10n, ThemeData theme) {
    return TextButton(
      onPressed: _toggleAuthMode,
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: 15,
            color: theme.brightness == Brightness.dark ? AppColors.textMuted : AppColors.lightTextMuted,
            fontFamily: theme.textTheme.bodyMedium?.fontFamily,
          ),
          children: [
            TextSpan(
              text: _isLoginMode
                  ? "${l10n.dontHaveLabAccess} "
                  : "${l10n.alreadyHaveLabAccess} ",
            ),
            TextSpan(
              text: _isLoginMode ? l10n.joinNow : l10n.signIn,
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom component for the profile header (including subscriber/scans usage details)
class ProfileHeaderCard extends StatelessWidget {
  final dynamic user;
  final int totalTests;
  final bool isPremium;
  final int freeScansLeft;
  final VoidCallback onUpgradePressed;

  const ProfileHeaderCard({
    super.key,
    required this.user,
    required this.totalTests,
    required this.isPremium,
    required this.freeScansLeft,
    required this.onUpgradePressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceBase : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDarkMode ? AppColors.borderSubtle : AppColors.lightBorderSubtle,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: isDarkMode ? AppColors.surfaceElevated : AppColors.lightBackgroundBase,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDarkMode ? AppColors.borderHighlight : AppColors.lightBorderSubtle,
                    width: 1,
                  ),
                ),
                child: user.photoUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.network(user.photoUrl!, fit: BoxFit.cover),
                      )
                    : Center(
                        child: Text(
                          user.username.isNotEmpty
                              ? user.username[0].toUpperCase()
                              : 'L',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.username,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$totalTests ${l10n.totalTests}',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!PremiumService.isPremiumReviewMode) ...[
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 20),
            
            // Premium Entitlement Status Bar
            if (isPremium)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryAccent, AppColors.tertiaryAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryAccent.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ]
                ),
                child: Row(
                  children: [
                    const Icon(HeroIcons.sparkles, color: Colors.white, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PRO Laboratory Account',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Unlimited scans and advanced reports active.',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode ? AppColors.surfaceElevated : AppColors.lightBackgroundBase,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDarkMode ? AppColors.borderHighlight : AppColors.lightBorderSubtle,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Free Scan Allowance',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isDarkMode ? Colors.white : AppColors.lightTextPrimary,
                          ),
                        ),
                        Text(
                          '$freeScansLeft / 3 left',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Progress bar showing consumed scans
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: freeScansLeft / 3.0,
                        backgroundColor: isDarkMode ? AppColors.borderSubtle : AppColors.lightBorderHighlight,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          freeScansLeft > 0 ? theme.colorScheme.primary : AppColors.statusError,
                        ),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Need unlimited analysis?',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDarkMode ? AppColors.textMuted : AppColors.lightTextMuted,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: onUpgradePressed,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.primaryAccent, AppColors.secondaryAccent],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(HeroIcons.sparkles, color: Colors.white, size: 13),
                                SizedBox(width: 6),
                                Text(
                                  'Upgrade',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// Custom component for the activity history list
class ActivityCard extends StatelessWidget {
  final List<TestResultEntity> results;

  const ActivityCard({super.key, required this.results});

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  Color _getConfidenceColor(int confidence, ThemeData theme) {
    if (confidence >= 80) return theme.colorScheme.primary;
    if (confidence >= 60) return theme.colorScheme.secondary;
    return theme.colorScheme.error;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdaptiveSectionTitle(
          title: l10n.recentActivity,
          showAccentBar: true,
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: isDarkMode ? AppColors.surfaceBase : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDarkMode ? AppColors.borderSubtle : AppColors.lightBorderSubtle,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: results.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(28.0),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          HeroIcons.beaker,
                          size: 32,
                          color: isDarkMode ? AppColors.textMuted : AppColors.lightTextMuted,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.noRecentActivity,
                          style: TextStyle(
                            color: isDarkMode ? AppColors.textMuted : AppColors.lightTextMuted,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: results.take(3).length,
                  separatorBuilder: (_, __) => const Divider(height: 1, indent: 44, endIndent: 16),
                  itemBuilder: (context, index) {
                    final result = results[index];
                    final color = _getConfidenceColor(result.confidencePercentage, theme);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: color.withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                )
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  result.reagentName,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode ? Colors.white : AppColors.lightTextPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  result.possibleSubstances.join(', '),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: isDarkMode ? AppColors.textSecondary : AppColors.lightTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _formatTimeAgo(result.testCompletedAt),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDarkMode ? AppColors.textMuted : AppColors.lightTextMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// Custom component for the safety instructions/reminders card
class SafetyReminderCard extends StatelessWidget {
  const SafetyReminderCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    final warningColor = isDarkMode ? AppColors.statusWarning : AppColors.lightStatusWarning;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: warningColor.withOpacity(isDarkMode ? 0.06 : 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: warningColor.withOpacity(0.25),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: warningColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  HeroIcons.exclamation_triangle,
                  color: warningColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.safetyReminder,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: isDarkMode ? Colors.white : AppColors.lightTextPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            l10n.safetyReminderText,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDarkMode ? AppColors.textSecondary : AppColors.lightTextSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom component for Account metadata
class AccountInfoCard extends StatelessWidget {
  final dynamic user;

  const AccountInfoCard({super.key, required this.user});

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdaptiveSectionTitle(
          title: l10n.accountInformation,
          showAccentBar: true,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: isDarkMode ? AppColors.surfaceBase : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDarkMode ? AppColors.borderSubtle : AppColors.lightBorderSubtle,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildInfoRow(
                context,
                HeroIcons.user,
                l10n.username,
                user.username,
              ),
              const Divider(height: 1),
              _buildInfoRow(
                context,
                HeroIcons.envelope,
                l10n.email,
                user.email,
              ),
              const Divider(height: 1),
              _buildInfoRow(
                context,
                HeroIcons.calendar,
                l10n.memberSince,
                _formatDate(user.registeredAt),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDarkMode ? AppColors.textMuted : AppColors.lightTextMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: isDarkMode ? Colors.white : AppColors.lightTextPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
