import 'package:flutter/material.dart';

import '../../domain/entities/settings_entity.dart';

class SettingsModel {
  final String themeMode;
  final String language;
  final bool pushNotificationsEnabled;
  final bool vibrationEnabled;
  final bool researchMode;

  const SettingsModel({
    required this.themeMode,
    required this.language,
    required this.pushNotificationsEnabled,
    required this.vibrationEnabled,
    required this.researchMode,
  });

  // Convert from Entity to Model
  factory SettingsModel.fromEntity(SettingsEntity entity) {
    return SettingsModel(
      themeMode: _themeModeToString(entity.themeMode),
      language: entity.language,
      pushNotificationsEnabled: entity.pushNotificationsEnabled,
      vibrationEnabled: entity.vibrationEnabled,
      researchMode: entity.researchMode,
    );
  }

  // Convert from JSON to Model
  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      themeMode: json['themeMode'] as String? ?? 'system',
      language: json['language'] as String? ?? 'en',
      pushNotificationsEnabled:
          json['pushNotificationsEnabled'] as bool? ?? true,
      vibrationEnabled: json['vibrationEnabled'] as bool? ?? true,
      researchMode: json['researchMode'] as bool? ?? false,
    );
  }

  // Convert Model to JSON
  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode,
      'language': language,
      'pushNotificationsEnabled': pushNotificationsEnabled,
      'vibrationEnabled': vibrationEnabled,
      'researchMode': researchMode,
    };
  }

  // Convert Model to Entity
  SettingsEntity toEntity() {
    return SettingsEntity(
      themeMode: _stringToThemeMode(themeMode),
      language: language,
      pushNotificationsEnabled: pushNotificationsEnabled,
      vibrationEnabled: vibrationEnabled,
      researchMode: researchMode,
    );
  }

  factory SettingsModel.defaultSettings() {
    return const SettingsModel(
      themeMode: 'system',
      language: 'en',
      pushNotificationsEnabled: true,
      vibrationEnabled: true,
      researchMode: false,
    );
  }

  SettingsModel copyWith({
    String? themeMode,
    String? language,
    bool? pushNotificationsEnabled,
    bool? vibrationEnabled,
    bool? researchMode,
  }) {
    return SettingsModel(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      pushNotificationsEnabled:
          pushNotificationsEnabled ?? this.pushNotificationsEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      researchMode: researchMode ?? this.researchMode,
    );
  }

  // Helper methods for theme mode conversion
  static String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  static ThemeMode _stringToThemeMode(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SettingsModel &&
        other.themeMode == themeMode &&
        other.language == language &&
        other.pushNotificationsEnabled == pushNotificationsEnabled &&
        other.vibrationEnabled == vibrationEnabled &&
        other.researchMode == researchMode;
  }

  @override
  int get hashCode {
    return themeMode.hashCode ^
        language.hashCode ^
        pushNotificationsEnabled.hashCode ^
        vibrationEnabled.hashCode ^
        researchMode.hashCode;
  }
}
