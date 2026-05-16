import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/settings_model.dart';

class SharedPreferencesService {
  static const String _settingsKey = 'app_settings';

  // Save settings to SharedPreferences
  Future<void> saveSettings(SettingsModel settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = json.encode(settings.toJson());
      await prefs.setString(_settingsKey, settingsJson);
    } catch (e) {
      throw Exception('Failed to save settings: $e');
    }
  }

  // Load settings from SharedPreferences
  Future<SettingsModel> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_settingsKey);

      if (settingsJson != null) {
        final settingsMap = json.decode(settingsJson) as Map<String, dynamic>;
        return SettingsModel.fromJson(settingsMap);
      } else {
        // Return default settings if none exist
        return SettingsModel.defaultSettings();
      }
    } catch (e) {
      // Return default settings if loading fails
      return SettingsModel.defaultSettings();
    }
  }

  // Clear all settings
  Future<void> clearSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_settingsKey);
    } catch (e) {
      throw Exception('Failed to clear settings: $e');
    }
  }

  // Check if settings exist
  Future<bool> hasSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_settingsKey);
    } catch (e) {
      return false;
    }
  }

  // Update specific setting
  Future<void> updateThemeMode(String themeMode) async {
    final currentSettings = await loadSettings();
    final updatedSettings = currentSettings.copyWith(themeMode: themeMode);
    await saveSettings(updatedSettings);
  }

  Future<void> updateLanguage(String language) async {
    final currentSettings = await loadSettings();
    final updatedSettings = currentSettings.copyWith(language: language);
    await saveSettings(updatedSettings);
  }

  Future<void> updatePushNotifications(bool enabled) async {
    final currentSettings = await loadSettings();
    final updatedSettings = currentSettings.copyWith(
      pushNotificationsEnabled: enabled,
    );
    await saveSettings(updatedSettings);
  }

  Future<void> updateVibration(bool enabled) async {
    final currentSettings = await loadSettings();
    final updatedSettings = currentSettings.copyWith(vibrationEnabled: enabled);
    await saveSettings(updatedSettings);
  }
}
