import 'package:flutter/material.dart';
import '../entities/settings_entity.dart';

abstract class SettingsRepository {
  Future<SettingsEntity> getSettings();
  Future<void> saveSettings(SettingsEntity settings);
  Future<void> updateThemeMode(ThemeMode themeMode);
  Future<void> updateLanguage(String language);
  Future<void> updatePushNotifications(bool enabled);
  Future<void> updateVibration(bool enabled);
  Future<void> resetToDefaults();
  Future<void> saveLanguage(String language);
  Future<String> getLanguage();
}
