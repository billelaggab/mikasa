import 'package:flutter/material.dart';
import 'package:mikasa/core/constants/app_colors.dart';
import 'package:mikasa/core/constants/app_strings.dart';

/// قائمة السياق التي تظهر فوق النص المحدد داخل قارئ PDF.
///
/// لا تحمل هذه القائمة أي منطق أعمال: تستقبل دوالّ استدعاء فقط،
/// ما يجعلها قابلة للاختبار وإعادة الاستخدام.
class ColorPickerMenu extends StatelessWidget {
  const ColorPickerMenu({
    super.key,
    required this.onColorSelected,
    required this.onCopy,
    required this.onNote,
  });

  final ValueChanged<int> onColorSelected;
  final VoidCallback onCopy;
  final VoidCallback onNote;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final List<String> colorNames = <String>[
      l10n.colorYellow,
      l10n.colorGreen,
      l10n.colorBlue,
      l10n.colorRed,
    ];

    return Material(
      elevation: 10,
      borderRadius: BorderRadius.circular(16),
      color: scheme.surface,
      shadowColor: Colors.black.withValues(alpha: 0.25),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (int index = 0; index < AppColors.highlightColors.length; index++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Tooltip(
                  message: colorNames[index],
                  child: InkResponse(
                    radius: 20,
                    onTap: () => onColorSelected(index),
                    child: Container(
                      width: 27,
                      height: 27,
                      decoration: BoxDecoration(
                        color: AppColors.highlightColors[index],
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.black.withValues(alpha: 0.10),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            Container(
              width: 1,
              height: 22,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              color: scheme.onSurface.withValues(alpha: 0.12),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: l10n.actionCopy,
              icon: const Icon(Icons.copy_rounded, size: 20),
              onPressed: onCopy,
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: l10n.actionAddNote,
              icon: const Icon(Icons.sticky_note_2_outlined, size: 20),
              onPressed: onNote,
            ),
          ],
        ),
      ),
    );
  }
}
