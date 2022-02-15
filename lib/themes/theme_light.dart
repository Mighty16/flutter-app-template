import 'package:flutter/material.dart';

import 'app_theme.dart';

class ThemeLight implements AppTheme {
  static const themeName = 'light';

  const ThemeLight();

  @override
  String get name => themeName;

  @override
  Color get appBarColor => Colors.white;

  @override
  ThemeData? get themeData => ThemeData.light();

  @override
  Color get appBarTextColor => Colors.black;
}
