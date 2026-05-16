import 'package:flutter/material.dart';
import '../../domain/entities/settings_entity.dart';
import '../../domain/repositories/settings_repository.dart';
import '../models/settings_model.dart';
import '../services/shared_preferences_service.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SharedPreferencesService _preferencesService;

  SettingsRepositoryImpl(this._preferencesService);

  @override
  Future<SettingsEntity> getSettings() async {
    try {
      final settingsModel = await _preferencesService.loadSettings();
      return settingsModel.toEntity();
    } catch (e) {
      // Return default settings if loading fails
      return SettingsModel.defaultSettings().toEntity();
    }
  }

  @override
  Future<void> saveSettings(SettingsEntity settings) async {
    try {
      final settingsModel = SettingsModel.fromEntity(settings);
      await _preferencesService.saveSettings(settingsModel);
    } catch (e) {
      throw Exception('Failed to save settings: $e');
    }
  }

  @override
  Future<void> updateThemeMode(ThemeMode themeMode) async {
    try {
      final themeModeString = _themeModeToString(themeMode);
      await _preferencesService.updateThemeMode(themeModeString);
    } catch (e) {
      throw Exception('Failed to update theme mode: $e');
    }
  }

  @override
  Future<void> updateLanguage(String language) async {
    try {
      await _preferencesService.updateLanguage(language);
    } catch (e) {
      throw Exception('Failed to update language: $e');
    }
  }

  @override
  Future<void> updatePushNotifications(bool enabled) async {
    try {
      await _preferencesService.updatePushNotifications(enabled);
    } catch (e) {
      throw Exception('Failed to update push notifications: $e');
    }
  }

  @override
  Future<void> updateVibration(bool enabled) async {
    try {
      await _preferencesService.updateVibration(enabled);
    } catch (e) {
      throw Exception('Failed to update vibration: $e');
    }
  }

  @override
  Future<void> resetToDefaults() async {
    try {
      await _preferencesService.clearSettings();
    } catch (e) {
      throw Exception('Failed to reset settings: $e');
    }
  }

  @override
  Future<String> getLanguage() async {
    final settings = await getSettings();
    return settings.language;
  }

  @override
  Future<void> saveLanguage(String language) async {
    final currentSettings = await getSettings();
    final newSettings = currentSettings.copyWith(language: language);
    await saveSettings(newSettings);
  }

  // Helper method for theme mode conversion
  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
