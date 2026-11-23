import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mikasa/core/constants/app_colors.dart';
import 'package:mikasa/core/constants/app_strings.dart';
import 'package:mikasa/core/utils/app_failure.dart';
import 'package:mikasa/core/utils/snackbars.dart';
import 'package:mikasa/models/book_model.dart';
import 'package:mikasa/models/highlight_model.dart';
import 'package:mikasa/providers/highlights_provider.dart';
import 'package:mikasa/providers/library_provider.dart';
import 'package:mikasa/router/app_router.dart';
import 'package:mikasa/widgets/empty_state.dart';
import 'package:mikasa/widgets/highlight_tile.dart';
import 'package:mikasa/widgets/note_editor_sheet.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

/// شاشة الاقتباسات.
///
/// - بدون `bookId`: تعرض اقتباسات كل الكتب (من المكتبة أو من Books المحذوفة).
/// - مع `bookId`: تعرض اقتباسات كتاب واحد، والضغط على اقتباس يعيد رقم الصفحة
///   إلى شاشة القارئ لتنتقل إليها عبر `PdfViewerController.jumpToPage`.
class HighlightsScreen extends StatefulWidget {
  const HighlightsScreen({super.key, this.bookId});

  final String? bookId;

  @override
  State<HighlightsScreen> createState() => _HighlightsScreenState();
}

class _HighlightsScreenState extends State<HighlightsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  int? _colorFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final HighlightsProvider highlights = context.watch<HighlightsProvider>();
    final LibraryProvider library = context.watch<LibraryProvider>();

    final String? bookId = widget.bookId;
    final bool isBookMode = bookId != null;

    String? bookTitle;
    if (bookId != null) {
      final BookModel? book = library.bookById(bookId);
      if (book != null) {
        bookTitle = book.title;
      } else {
        final List<HighlightModel> bookHighlights = highlights.forBook(bookId);
        bookTitle = bookHighlights.isEmpty ? null : bookHighlights.first.bookTitle;
      }
    }

    final List<HighlightModel> items = highlights.filter(
      bookId: bookId,
      colorIndex: _colorFilter,
      query: _query,
    );
    final bool hasAny = highlights.forBook(bookId).isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isBookMode && bookTitle != null
              ? l10n.bookQuotesTitle(bookTitle)
              : l10n.allQuotesTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _searchController,
              onChanged: (String value) => setState(() => _query = value),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: l10n.quotesSearchHint,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
              ),
            ),
          ),
          _buildColorFilter(l10n),
          Expanded(
            child: items.isEmpty
                ? EmptyState(
                    icon: hasAny ? Icons.filter_alt_off_rounded : Icons.format_quote_rounded,
                    title: hasAny ? l10n.quotesEmptyFilteredTitle : l10n.quotesEmptyTitle,
                    body: hasAny ? l10n.quotesEmptyFilteredBody : l10n.quotesEmptyBody,
                    actionLabel: hasAny ? l10n.quotesFilterAll : (isBookMode ? l10n.goRead : l10n.goToLibrary),
                    actionIcon: hasAny ? Icons.filter_alt_off_rounded : Icons.arrow_forward_rounded,
                    onAction: hasAny ? _clearFilters : () => _leaveEmptyState(isBookMode),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: items.length,
                    separatorBuilder: (BuildContext context, int index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (BuildContext context, int index) {
                      final HighlightModel highlight = items[index];
                      return HighlightTile(
                        highlight: highlight,
                        showBookTitle: !isBookMode,
                        onTap: () => _openHighlight(highlight),
                        onShare: () => _share(highlight, l10n),
                        onEditNote: () => _editNote(highlight),
                        onDelete: () => _delete(highlight, l10n),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorFilter(AppLocalizations l10n) {
    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        children: <Widget>[
          _FilterChip(
            label: l10n.quotesFilterAll,
            color: null,
            selected: _colorFilter == null,
            onTap: () => setState(() => _colorFilter = null),
          ),
          for (int index = 0; index < AppColors.highlightColors.length; index++)
            _FilterChip(
              label: _colorName(l10n, index),
              color: AppColors.highlightColors[index],
              selected: _colorFilter == index,
              onTap: () => setState(() => _colorFilter = index),
            ),
        ],
      ),
    );
  }

  String _colorName(AppLocalizations l10n, int index) {
    switch (index) {
      case 1:
        return l10n.colorGreen;
      case 2:
        return l10n.colorBlue;
      case 3:
        return l10n.colorRed;
      case 0:
      default:
        return l10n.colorYellow;
    }
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _query = '';
      _colorFilter = null;
    });
  }

  void _leaveEmptyState(bool isBookMode) {
    if (isBookMode) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(AppRoutes.library);
      }
    } else {
      context.go(AppRoutes.library);
    }
  }

  /// الانتقال إلى موضع الاقتباس داخل ملف PDF.
  void _openHighlight(HighlightModel highlight) {
    if (widget.bookId != null) {
      // في وضع الكتاب: نُعيد رقم الصفحة إلى القارئ ليتنقل إليها فوراً.
      context.pop<int>(highlight.pageNumber);
      return;
    }
    context.push(AppRoutes.readerAtPage(highlight.bookId, highlight.pageNumber));
  }

  Future<void> _share(HighlightModel highlight, AppLocalizations l10n) async {
    final StringBuffer buffer = StringBuffer()
      ..writeln(highlight.text)
      ..writeln()
      ..write(l10n.shareSignature(highlight.bookTitle));

    try {
      await SharePlus.instance.share(
        ShareParams(text: buffer.toString(), subject: l10n.shareSubject),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      showFailureSnackBar(context, FailureCode.unknown);
    }
  }

  Future<void> _editNote(HighlightModel highlight) async {
    final HighlightsProvider highlights = context.read<HighlightsProvider>();
    final String? note = await showNoteEditorSheet(context, initialNote: highlight.note);
    if (!mounted || note == null) {
      return;
    }
    await highlights.updateNote(highlight, note);
  }

  Future<void> _delete(HighlightModel highlight, AppLocalizations l10n) async {
    final HighlightsProvider highlights = context.read<HighlightsProvider>();
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(l10n.deleteQuoteTitle),
        content: Text(l10n.deleteQuoteBody),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.actionDelete),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }
    await highlights.delete(highlight);
  }
}

/// رقاقة فلترة لونية صغيرة.
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color? color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: ChoiceChip(
        selected: selected,
        onSelected: (_) => onTap(),
        avatar: color == null
            ? null
            : CircleAvatar(backgroundColor: color, radius: 7),
        label: Text(label),
        labelStyle: theme.textTheme.labelMedium?.copyWith(
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}
