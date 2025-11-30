import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartphone_client_app/core/security/secure_storage_service.dart';
import 'package:smartphone_client_app/core/theme/theme_preferences.dart';

/// Theme state
class ThemeState {
  final ThemePreferences preferences;
  final bool isLoading;

  const ThemeState({required this.preferences, this.isLoading = false});

  ThemeState copyWith({ThemePreferences? preferences, bool? isLoading}) {
    return ThemeState(
      preferences: preferences ?? this.preferences,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Theme cubit for managing app theme
class ThemeCubit extends Cubit<ThemeState> {
  final SecureStorageService _storage = SecureStorageService();

  ThemeCubit() : super(const ThemeState(preferences: ThemePreferences())) {
    _loadThemePreferences();
  }

  /// Load saved theme preferences
  Future<void> _loadThemePreferences() async {
    try {
      final json = await _storage.getThemePreferences();
      if (json != null) {
        final preferences = ThemePreferences.fromJson(json);
        emit(state.copyWith(preferences: preferences));
      }
    } catch (e) {
      // If loading fails, keep default preferences
    }
  }

  /// Update theme mode
  Future<void> setThemeMode(AppThemeMode mode) async {
    final newPreferences = state.preferences.copyWith(themeMode: mode);
    await _saveAndEmit(newPreferences);
  }

  /// Update color scheme
  Future<void> setColorScheme(AppColorScheme scheme) async {
    final newPreferences = state.preferences.copyWith(colorScheme: scheme);
    await _saveAndEmit(newPreferences);
  }

  /// Update both theme mode and color scheme
  Future<void> updateThemePreferences({
    AppThemeMode? themeMode,
    AppColorScheme? colorScheme,
  }) async {
    final newPreferences = state.preferences.copyWith(
      themeMode: themeMode,
      colorScheme: colorScheme,
    );
    await _saveAndEmit(newPreferences);
  }

  /// Save preferences and emit new state
  Future<void> _saveAndEmit(ThemePreferences preferences) async {
    try {
      emit(state.copyWith(isLoading: true));
      await _storage.saveThemePreferences(preferences.toJson());
      emit(state.copyWith(preferences: preferences, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false));
    }
  }
}
