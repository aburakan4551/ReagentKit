import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../data/services/shared_preferences_service.dart';
import '../../domain/repositories/settings_repository.dart';

import '../controllers/settings_controller.dart';
import '../states/settings_state.dart';

// Service Providers
final sharedPreferencesServiceProvider = Provider<SharedPreferencesService>((
  ref,
) {
  return SharedPreferencesService();
});

// Repository Providers
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final sharedPreferencesService = ref.watch(sharedPreferencesServiceProvider);
  return SettingsRepositoryImpl(sharedPreferencesService);
});

// Controller Providers
final settingsControllerProvider =
    StateNotifierProvider<SettingsController, SettingsState>((ref) {
  final settingsRepository = ref.watch(settingsRepositoryProvider);
  return SettingsController(settingsRepository);
});

// Convenience providers for specific settings values
final currentThemeModeProvider = Provider<String>((ref) {
  final settingsState = ref.watch(settingsControllerProvider);
  if (settingsState is SettingsLoaded) {
    switch (settingsState.settings.themeMode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
  return 'system'; // Default
});

final currentLanguageProvider = Provider<String>((ref) {
  final settingsState = ref.watch(settingsControllerProvider);
  if (settingsState is SettingsLoaded) {
    return settingsState.settings.language;
  }
  return 'en'; // Default
});

final pushNotificationsEnabledProvider = Provider<bool>((ref) {
  final settingsState = ref.watch(settingsControllerProvider);
  if (settingsState is SettingsLoaded) {
    return settingsState.settings.pushNotificationsEnabled;
  }
  return true; // Default
});

final vibrationEnabledProvider = Provider<bool>((ref) {
  final settingsState = ref.watch(settingsControllerProvider);
  if (settingsState is SettingsLoaded) {
    return settingsState.settings.vibrationEnabled;
  }
  return true; // Default
});

final researchModeEnabledProvider = Provider<bool>((ref) {
  final settingsState = ref.watch(settingsControllerProvider);
  if (settingsState is SettingsLoaded) {
    return settingsState.settings.researchMode;
  }
  return false; // Default
});

final localeProvider = Provider<Locale>((ref) {
  final SettingsState settingsState = ref.watch(settingsControllerProvider);
  if (settingsState is SettingsLoaded) {
    return Locale(settingsState.settings.language);
  }
  if (settingsState is SettingsSuccess) {
    return Locale(settingsState.settings.language);
  }
  return const Locale('en');
});
