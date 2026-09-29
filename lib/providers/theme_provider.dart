import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _themeModePreferenceKey = 'pref_theme_mode';

class ThemeModeController extends StateNotifier<ThemeMode> {
  ThemeModeController({
    SharedPreferences? preferences,
    ThemeMode initialMode = ThemeMode.system,
  })  : _preferences = preferences,
        super(initialMode);

  final SharedPreferences? _preferences;

  Future<void> setThemeMode(ThemeMode mode) async {
    final previousMode = state;
    state = mode;

    final preferences = _preferences;
    if (preferences == null) return;

    final stored =
        await preferences.setString(_themeModePreferenceKey, mode.name);
    if (!stored) {
      state = previousMode;
      throw StateError('Unable to save the theme preference on this device.');
    }
  }

  Future<void> toggleTheme() => setThemeMode(
        state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
      );

  static ThemeMode fromPreference(String? value) => switch (value) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeController, ThemeMode>((ref) {
  return ThemeModeController();
});
