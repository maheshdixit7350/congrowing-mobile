import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A simple app-level theme notifier that persists the user's choice.
class ThemeProvider extends ChangeNotifier {
  static const _key = 'dark_mode';

  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;

  ThemeProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final dark = prefs.getBool(_key) ?? false;
    _themeMode = dark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _themeMode = value ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }

  Future<void> toggle() async {
    await setDarkMode(!isDark);
  }
}

/// InheritedWidget so any descendant can access the provider without a package.
class ThemeProviderScope extends InheritedNotifier<ThemeProvider> {
  const ThemeProviderScope({
    super.key,
    required ThemeProvider provider,
    required super.child,
  }) : super(notifier: provider);

  static ThemeProvider of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ThemeProviderScope>();
    assert(scope != null, 'No ThemeProviderScope found in widget tree');
    return scope!.notifier!;
  }
}
