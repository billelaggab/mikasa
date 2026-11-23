import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:mikasa/core/constants/app_strings.dart';
import 'package:mikasa/core/theme/app_theme.dart';
import 'package:mikasa/providers/settings_provider.dart';
import 'package:provider/provider.dart';

/// جذر التطبيق: الثيم، اللغة (RTL/LTR)، والتوجيه.
class MikasaApp extends StatelessWidget {
  const MikasaApp({super.key, required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    final SettingsProvider settings = context.watch<SettingsProvider>();

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: settings.themeMode,
      locale: settings.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      onGenerateTitle: (BuildContext context) => AppLocalizations.of(context).appTitle,
    );
  }
}
