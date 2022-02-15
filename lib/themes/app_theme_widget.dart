import 'package:flutter/cupertino.dart';
import 'app_theme.dart';

class AppThemeWidget extends InheritedWidget {
  final AppTheme appTheme;

  const AppThemeWidget({
    Key? key,
    required this.appTheme,
    required Widget child,
  }) : super(key: key, child: child);

  static AppThemeWidget? of(BuildContext context){
    return context.dependOnInheritedWidgetOfExactType<AppThemeWidget>();
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => true;
}
