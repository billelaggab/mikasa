import 'package:flutter/material.dart';
import 'package:mikasa/core/constants/app_colors.dart';
import 'package:mikasa/core/constants/app_strings.dart';
import 'package:mikasa/core/utils/time_utils.dart';
import 'package:mikasa/models/highlight_model.dart';

/// بطاقة اقتباس واحدة في شاشة الاقتباسات.
class HighlightTile extends StatelessWidget {
  const HighlightTile({
    super.key,
    required this.highlight,
    required this.onTap,
    required this.onShare,
    required this.onEditNote,
    required this.onDelete,
    this.showBookTitle = false,
  });

  final HighlightModel highlight;
  final VoidCallback onTap;
  final VoidCallback onShare;
  final VoidCallback onEditNote;
  final VoidCallback onDelete;

  /// عند عرض اقتباسات كل الكتب، نُظهر اسم الكتاب أيضاً.
  final bool showBookTitle;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final Color accent = AppColors.highlightColor(highlight.colorIndex);

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // الشريط اللوني: يميّز لون التظليل (ويظهر على اليمين في RTL تلقائياً).
            Container(width: 5, color: accent),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      highlight.text,
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.65),
                    ),
                    if (highlight.hasNote) ...<Widget>[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Icon(
                              Icons.sticky_note_2_outlined,
                              size: 15,
                              color: scheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                highlight.note!,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            l10n.quotePage(highlight.pageNumber),
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (showBookTitle && highlight.bookTitle.isNotEmpty)
                          Expanded(
                            child: Text(
                              highlight.bookTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurface.withValues(alpha: 0.55),
                              ),
                            ),
                          )
                        else
                          Expanded(
                            child: Text(
                              formatShortDate(l10n, highlight.createdAt),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        PopupMenuButton<String>(
                          tooltip: '',
                          icon: Icon(
                            Icons.more_horiz_rounded,
                            color: scheme.onSurface.withValues(alpha: 0.55),
                          ),
                          onSelected: (String value) {
                            switch (value) {
                              case 'share':
                                onShare();
                              case 'note':
                                onEditNote();
                              case 'delete':
                                onDelete();
                            }
                          },
                          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                            PopupMenuItem<String>(
                              value: 'share',
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.share_outlined),
                                title: Text(l10n.actionShare),
                              ),
                            ),
                            PopupMenuItem<String>(
                              value: 'note',
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.edit_note_rounded),
                                title: Text(l10n.actionEditNote),
                              ),
                            ),
                            PopupMenuItem<String>(
                              value: 'delete',
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(Icons.delete_outline_rounded, color: scheme.error),
                                title: Text(
                                  l10n.actionDelete,
                                  style: TextStyle(color: scheme.error),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
