import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

/// Theme mode options
enum AppThemeMode { light, dark, system }

/// Color scheme options
enum AppColorScheme {
  dynamic, // Use Material You dynamic colors
  blue,
  red,
  green,
  purple,
  orange,
}

/// Theme preferences model
class ThemePreferences extends Equatable {
  final AppThemeMode themeMode;
  final AppColorScheme colorScheme;

  const ThemePreferences({
    this.themeMode = AppThemeMode.system,
    this.colorScheme = AppColorScheme.dynamic,
  });

  /// Convert to ThemeMode for MaterialApp
  ThemeMode get materialThemeMode {
    switch (themeMode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  /// Get seed color for color scheme
  Color? get seedColor {
    switch (colorScheme) {
      case AppColorScheme.dynamic:
        return null; // Use dynamic colors
      case AppColorScheme.blue:
        return Colors.blue;
      case AppColorScheme.red:
        return Colors.red;
      case AppColorScheme.green:
        return Colors.green;
      case AppColorScheme.purple:
        return Colors.purple;
      case AppColorScheme.orange:
        return Colors.orange;
    }
  }

  /// Get display name for theme mode
  String get themeModeDisplayName {
    switch (themeMode) {
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
      case AppThemeMode.system:
        return 'System default';
    }
  }

  /// Get display name for color scheme
  String get colorSchemeDisplayName {
    switch (colorScheme) {
      case AppColorScheme.dynamic:
        return 'Dynamic';
      case AppColorScheme.blue:
        return 'Blue';
      case AppColorScheme.red:
        return 'Red';
      case AppColorScheme.green:
        return 'Green';
      case AppColorScheme.purple:
        return 'Purple';
      case AppColorScheme.orange:
        return 'Orange';
    }
  }

  /// Copy with
  ThemePreferences copyWith({
    AppThemeMode? themeMode,
    AppColorScheme? colorScheme,
  }) {
    return ThemePreferences(
      themeMode: themeMode ?? this.themeMode,
      colorScheme: colorScheme ?? this.colorScheme,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {'themeMode': themeMode.name, 'colorScheme': colorScheme.name};
  }

  /// Create from JSON
  factory ThemePreferences.fromJson(Map<String, dynamic> json) {
    return ThemePreferences(
      themeMode: AppThemeMode.values.firstWhere(
        (e) => e.name == json['themeMode'],
        orElse: () => AppThemeMode.system,
      ),
      colorScheme: AppColorScheme.values.firstWhere(
        (e) => e.name == json['colorScheme'],
        orElse: () => AppColorScheme.dynamic,
      ),
    );
  }

  @override
  List<Object?> get props => [themeMode, colorScheme];
}
