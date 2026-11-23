import 'package:flutter/widgets.dart';

import 'package:tindascan/core/l10n/gen/app_localizations.dart';

export 'package:tindascan/core/l10n/gen/app_localizations.dart';

/// Shorthand: `context.l10n.loginTitle`.
extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
