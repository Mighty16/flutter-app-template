import 'package:flutter/material.dart';
import '../features/sample-feature/sample_feature_screen_widget.dart';
import '../themes/app_theme_widget.dart';
import '../l10n_ext.dart';
import '../themes/app_theme.dart';
import '../themes/theme_light.dart';

class App extends StatefulWidget {
  const App({Key? key}) : super(key: key);

  @override
  _AppState createState() => _AppState();

  static _AppState? of(BuildContext context) {
    return context.findAncestorStateOfType<_AppState>();
  }
}

class _AppState extends State<App> {
  Locale _locale = const Locale("en", "");
  AppTheme _appTheme = const ThemeLight();

  void setAppTheme(AppTheme appTheme) {
    setState(() {
      _appTheme = appTheme;
    });
  }

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppThemeWidget(
      appTheme: _appTheme,
      child: MaterialApp(
          onGenerateTitle: (BuildContext context) => context.texts().appName,
          locale: _locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: _appTheme.themeData,
          home: const SampleFeatureScreen()
          //navigatorKey: ,
          //home: SplashScreen(),
          ),
    );
  }
}
