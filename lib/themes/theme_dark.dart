import 'package:flutter/material.dart';

import 'app_theme.dart';

class ThemeDark implements AppTheme {
  const ThemeDark();

  @override
  Color get appBarColor => Colors.black;

  @override
  ThemeData? get themeData => ThemeData.dark();

  @override
  String get name => 'dark';

  @override
  Color get appBarTextColor => Colors.white;
}
