import 'package:flutter/material.dart';

abstract class AppTheme {
  //Custom theme fields
  String get name;
  Color get appBarColor;
  Color get appBarTextColor;
  ThemeData? get themeData;
}
