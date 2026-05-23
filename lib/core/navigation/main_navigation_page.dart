import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:reagentkit/l10n/app_localizations.dart';
import '../widgets/auth_guard.dart';
import '../../features/profile/presentation/views/profile_page.dart';
import '../../features/reagent_testing/presentation/views/reagent_testing_page.dart';
import '../../features/reagent_testing/presentation/views/test_result_history_page.dart';
import '../../features/settings/presentation/views/settings_page.dart';

class MainNavigationPage extends ConsumerStatefulWidget {
  const MainNavigationPage({super.key});

  @override
  ConsumerState<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends ConsumerState<MainNavigationPage> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkConsent();
    });
  }

  Future<void> _checkConsent() async {
    final prefs = await SharedPreferences.getInstance();
    final accepted = prefs.getBool('legal_consent_accepted') ?? false;
    if (!accepted && mounted) {
      _showConsentDialog();
    }
  }

  void _showConsentDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const _ConsentDialog();
      },
    );
  }

  List<Widget> get _pages => [
    AuthGuard(
      redirectMessage:
          'Sign in to start testing reagents and view your results.',
      child: const ReagentTestingPage(),
    ),
    AuthGuard(
      redirectMessage:
          'Sign in to view your test history and track your results.',
      child: const TestResultHistoryPage(),
    ),
    AuthGuard(
      redirectMessage: 'Sign in to access app settings and preferences.',
      child: const SettingsPage(),
    ),
    const ProfilePage(), // Profile page handles its own auth state
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).padding.bottom;
    
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          IndexedStack(index: _selectedIndex, children: _pages),
          Positioned(
            left: 24,
            right: 24,
            bottom: bottomInset > 0 ? bottomInset : 24,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  height: 72,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavItem(0, HeroIcons.beaker),
                      _buildNavItem(1, HeroIcons.clock),
                      _buildNavItem(2, HeroIcons.cog_6_tooth),
                      _buildNavItem(3, HeroIcons.user_circle),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon) {
    final isSelected = _selectedIndex == index;
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 60,
        height: 60,
        alignment: Alignment.center,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected 
                ? theme.colorScheme.primary.withValues(alpha: 0.15) 
                : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: isSelected ? 28 : 24,
            color: isSelected 
                ? theme.colorScheme.primary 
                : theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}

class _ConsentDialog extends StatefulWidget {
  const _ConsentDialog();

  @override
  State<_ConsentDialog> createState() => _ConsentDialogState();
}

class _ConsentDialogState extends State<_ConsentDialog> {
  bool _isChecked = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: theme.dialogTheme.backgroundColor ?? theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      HeroIcons.shield_exclamation,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isAr ? 'إقرار وموافقة قانونية' : 'Legal Consent & Disclaimer',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Divider(color: theme.dividerColor),
              const SizedBox(height: 12),
              // English text
              Text(
                'Scientific Disclaimer:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Interpretations generated by this application are probabilistic analytical observations and not certified scientific conclusions. This application is intended solely for educational, analytical, and research-support workflows.',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              // Arabic text
              Text(
                'إخلاء المسؤولية العلمية:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'النتائج المعروضة هي تفسيرات تحليلية احتمالية لأغراض تعليمية وبحثية فقط، ولا تمثل نتائج علمية أو مخبرية معتمدة.',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Divider(color: theme.dividerColor),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: _isChecked,
                onChanged: (val) {
                  setState(() {
                    _isChecked = val ?? false;
                  });
                },
                title: Text(
                  l10n.understandLimitations,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: theme.colorScheme.primary,
                checkColor: Colors.white,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isChecked
                      ? () async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('legal_consent_accepted', true);
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    disabledBackgroundColor: theme.dividerColor.withValues(alpha: 0.12),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    isAr ? 'قبول ومتابعة' : 'Accept & Continue',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _isChecked ? Colors.white : theme.colorScheme.onSurface.withValues(alpha: 0.38),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Placeholder Pages - Will be implemented in their respective features
