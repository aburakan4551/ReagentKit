import 'package:flutter/material.dart';

class SettingsEntity {
  final ThemeMode themeMode;
  final String language;
  final bool pushNotificationsEnabled;
  final bool vibrationEnabled;

  const SettingsEntity({
    required this.themeMode,
    required this.language,
    required this.pushNotificationsEnabled,
    required this.vibrationEnabled,
  });

  SettingsEntity copyWith({
    ThemeMode? themeMode,
    String? language,
    bool? pushNotificationsEnabled,
    bool? vibrationEnabled,
  }) {
    return SettingsEntity(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      pushNotificationsEnabled:
          pushNotificationsEnabled ?? this.pushNotificationsEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SettingsEntity &&
        other.themeMode == themeMode &&
        other.language == language &&
        other.pushNotificationsEnabled == pushNotificationsEnabled &&
        other.vibrationEnabled == vibrationEnabled;
  }

  @override
  int get hashCode {
    return themeMode.hashCode ^
        language.hashCode ^
        pushNotificationsEnabled.hashCode ^
        vibrationEnabled.hashCode;
  }
}
