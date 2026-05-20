import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:icons_plus/icons_plus.dart';
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
                    color: theme.colorScheme.surface.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
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
                ? theme.colorScheme.primary.withOpacity(0.15) 
                : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: isSelected ? 28 : 24,
            color: isSelected 
                ? theme.colorScheme.primary 
                : theme.colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      ),
    );
  }
}

// Placeholder Pages - Will be implemented in their respective features
