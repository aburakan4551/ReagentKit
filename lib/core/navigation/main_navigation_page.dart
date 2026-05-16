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
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: [
          BottomNavigationBarItem(
            icon: Icon(HeroIcons.beaker), // Lab testing icon
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(HeroIcons.clock), // History/time icon
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(HeroIcons.cog_6_tooth), // Settings gear icon
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(HeroIcons.user_circle), // Profile icon
            label: '',
          ),
        ],
      ),
    );
  }
}

// Placeholder Pages - Will be implemented in their respective features
