export 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'l10n_ext.dart';

extension LocalizationExt on BuildContext {
  AppLocalizations texts() => AppLocalizations.of(this);
}
