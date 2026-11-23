import 'package:flutter/material.dart';
import 'package:mikasa/core/constants/app_colors.dart';
import 'package:mikasa/core/constants/app_strings.dart';
import 'package:mikasa/core/utils/time_utils.dart';
import 'package:mikasa/models/book_model.dart';

/// بطاقة كتاب في شاشة المكتبة.
///
/// - Hero Animation: غلاف الكتاب يطير إلى شاشة القراءة.
/// - تعرض: العنوان، الصفحة الحالية، عدد الاقتباسات، آخر وقت فتح، والتقدم.
class BookCard extends StatelessWidget {
  const BookCard({
    super.key,
    required this.book,
    required this.highlightCount,
    required this.onTap,
    required this.onShowHighlights,
    required this.onDelete,
  });

  final BookModel book;
  final int highlightCount;
  final VoidCallback onTap;
  final VoidCallback onShowHighlights;
  final VoidCallback onDelete;

  static String heroTag(String bookId) => 'book-cover-$bookId';

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final int percent = (book.progress * 100).round();

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Hero(
                tag: heroTag(book.id),
                child: _BookCover(title: book.title),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      book.totalPages > 0
                          ? '${l10n.bookPageOf(book.lastPage, book.totalPages)} · ${l10n.bookProgress(percent)}'
                          : l10n.bookPages(book.totalPages),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: book.progress == 0 ? 0.02 : book.progress,
                        minHeight: 5,
                        backgroundColor: scheme.onSurface.withValues(alpha: 0.08),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: <Widget>[
                        Icon(
                          Icons.format_quote_rounded,
                          size: 15,
                          color: AppColors.highlightColor(0).withValues(alpha: 0.95),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          l10n.bookHighlights(highlightCount),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l10n.bookLastOpened(formatRelativeTime(l10n, book.lastOpened)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: '',
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: scheme.onSurface.withValues(alpha: 0.55),
                ),
                onSelected: (String value) {
                  if (value == 'quotes') {
                    onShowHighlights();
                  } else if (value == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'quotes',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.format_quote_rounded),
                      title: Text(l10n.allQuotesTitle),
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
        ),
      ),
    );
  }
}

/// غلاف رمزي للكتاب (لا نحتاج تحميل الغلاف الحقيقي من PDF).
class _BookCover extends StatelessWidget {
  const _BookCover({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      width: 58,
      height: 78,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            scheme.primary,
            scheme.primary.withValues(alpha: 0.72),
            AppColors.secondary.withValues(alpha: 0.85),
          ],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          _initials(title),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
        ),
      ),
    );
  }

  /// أول حرفين من العنوان كغلاف مصغّر.
  String _initials(String value) {
    final String trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'PDF';
    }
    final List<String> words = trimmed.split(RegExp(r'\s+'));
    if (words.length >= 2 && words[1].isNotEmpty) {
      return '${words[0][0]}${words[1][0]}';
    }
    return trimmed.substring(0, trimmed.length >= 2 ? 2 : 1);
  }
}
