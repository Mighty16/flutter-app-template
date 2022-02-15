import 'package:flutter/material.dart';
import '../l10n_ext.dart';

class App extends StatefulWidget {
  const App({Key? key}) : super(key: key);

  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  Locale _locale = Locale("en", "");

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (BuildContext context) => context.texts().appName,
      locale: _locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,

      //theme: ,
      //navigatorKey: ,
      //home: SplashScreen(),
    );
  }
}
