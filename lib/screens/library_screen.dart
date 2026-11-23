import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mikasa/core/constants/app_strings.dart';
import 'package:mikasa/core/utils/snackbars.dart';
import 'package:mikasa/models/book_model.dart';
import 'package:mikasa/providers/highlights_provider.dart';
import 'package:mikasa/providers/library_provider.dart';
import 'package:mikasa/router/app_router.dart';
import 'package:mikasa/widgets/book_card.dart';
import 'package:mikasa/widgets/empty_state.dart';
import 'package:mikasa/widgets/settings_sheet.dart';
import 'package:provider/provider.dart';

/// شاشة المكتبة: كل ملفات PDF التي فتحها المستخدم.
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final LibraryProvider library = context.watch<LibraryProvider>();
    final HighlightsProvider highlights = context.watch<HighlightsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(l10n.appTitle),
            Text(
              l10n.librarySubtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            tooltip: l10n.allQuotesTitle,
            icon: const Icon(Icons.format_quote_rounded),
            onPressed: () => context.push(AppRoutes.allHighlights),
          ),
          IconButton(
            tooltip: l10n.settingsTitle,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => showSettingsSheet(context),
          ),
        ],
      ),
      body: _buildBody(context, library, highlights, l10n),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: library.isImporting ? null : () => _importBook(context),
        icon: library.isImporting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.add_rounded),
        label: Text(library.isImporting ? l10n.importing : l10n.importPdf),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    LibraryProvider library,
    HighlightsProvider highlights,
    AppLocalizations l10n,
  ) {
    if (library.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (library.isEmpty) {
      return EmptyState(
        icon: Icons.auto_stories_rounded,
        title: l10n.libraryEmptyTitle,
        body: l10n.libraryEmptyBody,
        actionLabel: l10n.importPdf,
        actionIcon: Icons.file_open_rounded,
        onAction: () => _importBook(context),
      );
    }

    final List<BookModel> books = library.books;
    return RefreshIndicator(
      onRefresh: library.loadBooks,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 110),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: books.length,
        separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 12),
        itemBuilder: (BuildContext context, int index) {
          final BookModel book = books[index];
          return BookCard(
            book: book,
            highlightCount: highlights.countForBook(book.id),
            onTap: () => context.push(AppRoutes.reader(book.id)),
            onShowHighlights: () => context.push(AppRoutes.bookHighlights(book.id)),
            onDelete: () => _confirmDelete(context, book, library),
          );
        },
      ),
    );
  }

  Future<void> _importBook(BuildContext context) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final LibraryProvider library = context.read<LibraryProvider>();

    final BookModel? book = await library.importBook();
    if (!context.mounted) {
      return;
    }

    if (book != null) {
      showInfoSnackBar(context, l10n.importSuccess);
    } else if (library.lastFailure != null) {
      showFailureSnackBar(context, library.lastFailure);
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    BookModel book,
    LibraryProvider library,
  ) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final HighlightsProvider highlights = context.read<HighlightsProvider>();

    final String? choice = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(l10n.deleteBookTitle),
        content: Text('${l10n.deleteBookBody}\n\n${book.title}'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop('keep'),
            child: Text(l10n.deleteBookKeepQuotes),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop('with'),
            child: Text(l10n.deleteBookWithQuotes),
          ),
        ],
      ),
    );

    if (choice == null) {
      return;
    }

    await library.deleteBook(book, deleteHighlights: choice == 'with');
    await highlights.load();

    if (!context.mounted) {
      return;
    }
    showInfoSnackBar(context, l10n.deleteBookSuccess);
  }
}
