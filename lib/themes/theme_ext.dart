import 'package:flutter/cupertino.dart';
import '../themes/app_theme.dart';

import 'app_theme_widget.dart';
import 'theme_light.dart';

extension AppThemeExt on BuildContext {
  AppTheme theme() {
    return AppThemeWidget.of(this)?.appTheme ?? const ThemeLight();
  }
}
