import 'package:flutter/material.dart';
import 'package:mikasa/core/constants/app_strings.dart';

/// شريط التنقل السريع بين الصفحات داخل القارئ:
/// Slider + إدخال رقم الصفحة + أزرار السابق/التالي.
class PageNavigatorBar extends StatefulWidget {
  const PageNavigatorBar({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onJump,
  });

  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onJump;

  @override
  State<PageNavigatorBar> createState() => _PageNavigatorBarState();
}

class _PageNavigatorBarState extends State<PageNavigatorBar> {
  /// قيمة السلايدر أثناء السحب (لا ننتقل للصفحة إلا عند إفلاته، لتجنّب تقطيع التمرير).
  double? _dragValue;

  int get _maxPage => widget.totalPages < 1 ? 1 : widget.totalPages;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final bool canGoBack = widget.currentPage > 1;
    final bool canGoForward = widget.currentPage < _maxPage;
    final int shownPage = (_dragValue?.round() ?? widget.currentPage).clamp(1, _maxPage);

    return Material(
      color: theme.colorScheme.surface,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  IconButton(
                    tooltip: l10n.previousPage,
                    visualDensity: VisualDensity.compact,
                    onPressed: canGoBack ? () => widget.onJump(widget.currentPage - 1) : null,
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  Expanded(
                    child: Center(
                      child: TextButton(
                        onPressed: widget.totalPages > 0 ? _promptPage : null,
                        child: Text(
                          l10n.readerPageOfShort(shownPage, _maxPage),
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.nextPage,
                    visualDensity: VisualDensity.compact,
                    onPressed: canGoForward ? () => widget.onJump(widget.currentPage + 1) : null,
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
              SizedBox(
                height: 28,
                child: Slider(
                  min: 1,
                  max: _maxPage.toDouble(),
                  value: shownPage.toDouble(),
                  onChanged: _maxPage <= 1
                      ? null
                      : (double value) => setState(() => _dragValue = value),
                  onChangeEnd: (double value) {
                    setState(() => _dragValue = null);
                    widget.onJump(value.round());
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _promptPage() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final TextEditingController controller =
        TextEditingController(text: widget.currentPage.toString());

    final String? value = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(l10n.readerGoToPage),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(hintText: l10n.readerPageHint),
          onSubmitted: (String text) => Navigator.of(dialogContext).pop(text),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: Text(l10n.actionSave),
          ),
        ],
      ),
    );

    controller.dispose();
    if (!mounted || value == null) {
      return;
    }

    final int? parsed = int.tryParse(value.trim());
    if (parsed == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.readerPageInvalid)),
      );
      return;
    }
    widget.onJump(parsed.clamp(1, _maxPage));
  }
}
