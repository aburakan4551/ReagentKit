import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/settings_entity.dart';
import '../../domain/repositories/settings_repository.dart';
import '../states/settings_state.dart';

class SettingsController extends StateNotifier<SettingsState> {
  final SettingsRepository _settingsRepository;

  SettingsController(this._settingsRepository)
    : super(const SettingsLoading()) {
    _loadSettings();
  }

  Future<void> loadSettings() async {
    await _loadSettings();
  }

  Future<void> _loadSettings() async {
    state = const SettingsLoading();
    try {
      final settings = await _settingsRepository.getSettings();
      state = SettingsLoaded(settings);
    } catch (e) {
      state = SettingsError(e.toString());
    }
  }

  Future<void> changeLanguage(String language) async {
    final currentState = state;
    if (currentState is SettingsLoaded) {
      try {
        await _settingsRepository.saveLanguage(language);
        state = SettingsLoaded(
          currentState.settings.copyWith(language: language),
        );
      } catch (e) {
        state = SettingsError('Failed to change language: $e');
      }
    }
  }

  Future<void> updateTheme(ThemeMode themeMode) async {
    final currentState = state;
    if (currentState is! SettingsLoaded) return;

    state = const SettingsLoading();
    try {
      await _settingsRepository.updateThemeMode(themeMode);
      final updatedSettings = currentState.settings.copyWith(
        themeMode: themeMode,
      );
      state = SettingsSuccess('Theme updated successfully', updatedSettings);
      // After showing success, return to loaded state
      await Future.delayed(const Duration(milliseconds: 500));
      state = SettingsLoaded(updatedSettings);
    } catch (e) {
      state = SettingsError('Failed to update theme: $e');
      // Return to previous state after error
      await Future.delayed(const Duration(seconds: 2));
      state = currentState;
    }
  }

  Future<void> updateLanguage(String language) async {
    final SettingsState currentState = state;
    if (currentState is! SettingsLoaded) {
      return;
    }
    try {
      await _settingsRepository.updateLanguage(language);
      final SettingsEntity updatedSettings = currentState.settings.copyWith(
        language: language,
      );
      state = SettingsLoaded(updatedSettings);
    } catch (e) {
      state = SettingsError('Failed to update language: $e');
      await Future.delayed(const Duration(seconds: 2));
      state = currentState;
    }
  }

  Future<void> updatePushNotifications(bool enabled) async {
    final currentState = state;
    if (currentState is! SettingsLoaded) return;

    state = const SettingsLoading();
    try {
      await _settingsRepository.updatePushNotifications(enabled);
      final updatedSettings = currentState.settings.copyWith(
        pushNotificationsEnabled: enabled,
      );
      state = SettingsSuccess(
        'Push notifications updated successfully',
        updatedSettings,
      );
      // After showing success, return to loaded state
      await Future.delayed(const Duration(milliseconds: 500));
      state = SettingsLoaded(updatedSettings);
    } catch (e) {
      state = SettingsError('Failed to update push notifications: $e');
      // Return to previous state after error
      await Future.delayed(const Duration(seconds: 2));
      state = currentState;
    }
  }

  Future<void> updateVibration(bool enabled) async {
    final currentState = state;
    if (currentState is! SettingsLoaded) return;

    state = const SettingsLoading();
    try {
      await _settingsRepository.updateVibration(enabled);
      final updatedSettings = currentState.settings.copyWith(
        vibrationEnabled: enabled,
      );
      state = SettingsSuccess(
        'Vibration updated successfully',
        updatedSettings,
      );
      // After showing success, return to loaded state
      await Future.delayed(const Duration(milliseconds: 500));
      state = SettingsLoaded(updatedSettings);
    } catch (e) {
      state = SettingsError('Failed to update vibration: $e');
      // Return to previous state after error
      await Future.delayed(const Duration(seconds: 2));
      state = currentState;
    }
  }

  Future<void> resetToDefaults() async {
    final currentState = state;
    if (currentState is! SettingsLoaded) return;

    state = const SettingsLoading();
    try {
      await _settingsRepository.resetToDefaults();
      final defaultSettings = await _settingsRepository.getSettings();
      state = SettingsSuccess('Settings reset successfully', defaultSettings);
      // After showing success, return to loaded state
      await Future.delayed(const Duration(milliseconds: 500));
      state = SettingsLoaded(defaultSettings);
    } catch (e) {
      state = SettingsError('Failed to reset settings: $e');
      // Return to previous state after error
      await Future.delayed(const Duration(seconds: 2));
      state = currentState;
    }
  }

  // Refresh settings
  Future<void> refreshSettings() async {
    await loadSettings();
  }
}
