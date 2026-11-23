import 'package:flutter/material.dart';
import 'package:mikasa/core/constants/app_strings.dart';
import 'package:mikasa/providers/settings_provider.dart';
import 'package:provider/provider.dart';

/// لوحة الإعدادات: المظهر، اللغة، ووضع القراءة الليلي.
Future<void> showSettingsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (BuildContext context) => const _SettingsSheet(),
  );
}

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final SettingsProvider settings = context.watch<SettingsProvider>();
    final ThemeData theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              l10n.settingsTitle,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),

            _SectionTitle(label: l10n.settingsAppearance),
            const SizedBox(height: 10),
            SegmentedButton<ThemeMode>(
              showSelectedIcon: false,
              segments: <ButtonSegment<ThemeMode>>[
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.system,
                  label: Text(l10n.settingsThemeSystem),
                  icon: const Icon(Icons.brightness_auto_rounded, size: 18),
                ),
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.light,
                  label: Text(l10n.settingsThemeLight),
                  icon: const Icon(Icons.light_mode_rounded, size: 18),
                ),
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.dark,
                  label: Text(l10n.settingsThemeDark),
                  icon: const Icon(Icons.dark_mode_rounded, size: 18),
                ),
              ],
              selected: <ThemeMode>{settings.themeMode},
              onSelectionChanged: (Set<ThemeMode> selection) {
                settings.setThemeMode(selection.first);
              },
            ),

            const SizedBox(height: 22),
            _SectionTitle(label: l10n.settingsLanguage),
            const SizedBox(height: 6),
            RadioGroup<String>(
              groupValue: settings.locale.languageCode,
              onChanged: (String? value) {
                if (value != null) {
                  settings.setLocale(Locale(value));
                }
              },
              child: Column(
                children: <Widget>[
                  RadioListTile<String>(
                    value: 'ar',
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.settingsArabic),
                  ),
                  RadioListTile<String>(
                    value: 'en',
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.settingsEnglish),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            SwitchListTile(
              value: settings.nightReadingMode,
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.settingsNightReading),
              subtitle: Text(
                l10n.settingsNightReadingHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              onChanged: settings.setNightReadingMode,
            ),

            const SizedBox(height: 20),
            _SectionTitle(label: l10n.settingsAbout),
            const SizedBox(height: 8),
            Text(
              l10n.settingsAboutBody,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.primary,
          ),
    );
  }
}
