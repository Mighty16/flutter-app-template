import 'package:flutter/material.dart';
import '../../themes/theme_light.dart';
import '../../themes/app_theme.dart';
import '../../themes/theme_dark.dart';
import '../../app/app.dart';
import '../../themes/theme_ext.dart';

class SampleFeatureScreen extends StatelessWidget {
  const SampleFeatureScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    AppTheme theme = context.theme();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.theme().appBarColor,
        title: Text(
          'Sample feature',
          style: TextStyle(color: theme.appBarTextColor),
        ),
      ),
      body: Center(
        child: ElevatedButton(
          child: const Text('Change theme'),
          onPressed: () {
            bool isLight = theme.name == ThemeLight.themeName;
            App.of(context)
                ?.setAppTheme(isLight ? const ThemeDark() : const ThemeLight());
          },
        ),
      ),
    );
  }
}
