import '../../domain/entities/settings_entity.dart';

abstract class SettingsState {
  const SettingsState();
}

class SettingsInitial extends SettingsState {
  const SettingsInitial();
}

class SettingsLoading extends SettingsState {
  const SettingsLoading();
}

class SettingsLoaded extends SettingsState {
  final SettingsEntity settings;

  const SettingsLoaded(this.settings);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SettingsLoaded && other.settings == settings;
  }

  @override
  int get hashCode => settings.hashCode;
}

class SettingsError extends SettingsState {
  final String message;

  const SettingsError(this.message);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SettingsError && other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}

class SettingsSuccess extends SettingsState {
  final String message;
  final SettingsEntity settings;

  const SettingsSuccess(this.message, this.settings);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SettingsSuccess &&
        other.message == message &&
        other.settings == settings;
  }

  @override
  int get hashCode => message.hashCode ^ settings.hashCode;
}
