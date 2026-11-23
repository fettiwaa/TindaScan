import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tindascan/core/l10n/l10n.dart';
import 'package:tindascan/core/router/app_router.dart';
import 'package:tindascan/core/theme/app_theme.dart';
import 'package:tindascan/core/theme/app_tokens.dart';
import 'package:tindascan/core/widgets/offline_banner.dart';
import 'package:tindascan/features/sales/application/cart_notifier.dart';
import 'package:tindascan/features/settings/application/app_preferences.dart';
import 'package:tindascan/features/settings/application/locale_provider.dart';

/// Root widget: theme, localization and router.
class TindaScanApp extends ConsumerWidget {
  const TindaScanApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(cartSessionGuardProvider);
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider).value;
    final themeMode = ref.watch(
      appPreferencesProvider.select(
        (p) => p.value?.themeMode ?? ThemeMode.system,
      ),
    );
    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.appTitle,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      themeAnimationDuration: AppMotion.normal,
      themeAnimationCurve: AppMotion.transition,
      routerConfig: router,
      locale: locale,
      builder: (context, child) =>
          OfflineBanner(child: child ?? const SizedBox.shrink()),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}

/// Shown instead of the app when no Firebase configuration was supplied, so
/// a misconfigured build fails loudly but gracefully.
class FirebaseNotConfiguredApp extends StatelessWidget {
  const FirebaseNotConfiguredApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: AppTheme.light(),
    darkTheme: AppTheme.dark(),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Builder(
      builder: (context) => Scaffold(
        appBar: AppBar(title: Text(context.l10n.firebaseNotConfiguredTitle)),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(context.l10n.firebaseNotConfiguredMessage),
        ),
      ),
    ),
  );
}
