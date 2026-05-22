import 'package:flutter/material.dart';

class SettingsEntity {
  final ThemeMode themeMode;
  final String language;
  final bool pushNotificationsEnabled;
  final bool vibrationEnabled;
  final bool researchMode;

  const SettingsEntity({
    required this.themeMode,
    required this.language,
    required this.pushNotificationsEnabled,
    required this.vibrationEnabled,
    this.researchMode = false,
  });

  SettingsEntity copyWith({
    ThemeMode? themeMode,
    String? language,
    bool? pushNotificationsEnabled,
    bool? vibrationEnabled,
    bool? researchMode,
  }) {
    return SettingsEntity(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      pushNotificationsEnabled:
          pushNotificationsEnabled ?? this.pushNotificationsEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      researchMode: researchMode ?? this.researchMode,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SettingsEntity &&
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
