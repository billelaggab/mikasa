import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:mikasa/core/constants/app_colors.dart';
import 'package:mikasa/core/constants/app_strings.dart';
import 'package:mikasa/core/utils/app_failure.dart';
import 'package:mikasa/core/utils/snackbars.dart';
import 'package:mikasa/models/book_model.dart';
import 'package:mikasa/models/highlight_model.dart';
import 'package:mikasa/providers/highlights_provider.dart';
import 'package:mikasa/providers/library_provider.dart';
import 'package:mikasa/providers/settings_provider.dart';
import 'package:mikasa/router/app_router.dart';
import 'package:mikasa/services/database_service.dart';
import 'package:mikasa/services/file_service.dart';
import 'package:mikasa/widgets/book_card.dart';
import 'package:mikasa/widgets/color_picker_menu.dart';
import 'package:mikasa/widgets/note_editor_sheet.dart';
import 'package:mikasa/widgets/page_navigator_bar.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

/// شاشة القراءة: عرض PDF + تحديد النص وتظليله فعلياً داخل الصفحة.
class PdfReaderScreen extends StatefulWidget {
  const PdfReaderScreen({
    super.key,
    required this.bookId,
    this.initialPage,
  });

  final String bookId;

  /// عند القدوم من اقتباس معيّن، نفتح على صفحته مباشرة.
  final int? initialPage;

  @override
  State<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends State<PdfReaderScreen> {
  /// مصفوفة عكس الألوان (Invert) لوضع القراءة الليلي.
  static const List<double> _invertMatrix = <double>[
    -1, 0, 0, 0, 255, //
    0, -1, 0, 0, 255, //
    0, 0, -1, 0, 255, //
    0, 0, 0, 1, 0, //
  ];

  /// مصفوفة محايدة: نُبقي شجرة الودجات ثابتة حتى لا يُعاد تحميل المستند
  /// عند تبديل الوضع الليلي (وهو خطأ شائع يفقِد المستخدم موضعه في الصفحة).
  static const List<double> _identityMatrix = <double>[
    1, 0, 0, 0, 0, //
    0, 1, 0, 0, 0, //
    0, 0, 1, 0, 0, //
    0, 0, 0, 1, 0, //
  ];

  final PdfViewerController _controller = PdfViewerController();
  final GlobalKey<SfPdfViewerState> _viewerKey = GlobalKey<SfPdfViewerState>();

  // نُمسك مراجع الـ Providers في initState حتى لا نستخدم BuildContext
  // بعد عمليات await (تفادي أخطاء "widget unmounted").
  late final LibraryProvider _library;
  late final HighlightsProvider _highlights;
  late final FileService _fileService;
  late final DatabaseService _database;
  late final SettingsProvider _settings;

  OverlayEntry? _selectionMenu;
  PdfTextSelectionChangedDetails? _selection;
  BookModel? _book;

  Timer? _progressDebounce;
  bool _documentLoaded = false;
  bool _fileMissing = false;
  String? _loadError;
  int _viewerVersion = 0;
  int _currentPage = 1;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _library = context.read<LibraryProvider>();
    _highlights = context.read<HighlightsProvider>();
    _fileService = context.read<FileService>();
    _database = context.read<DatabaseService>();
    _settings = context.read<SettingsProvider>();

    _book = _library.bookById(widget.bookId);
    _currentPage = widget.initialPage ?? _book?.lastPage ?? 1;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_verifyFileExists());
    });
  }

  @override
  void dispose() {
    _progressDebounce?.cancel();
    _removeSelectionMenu();
    unawaited(_persistProgress());
    _controller.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------ تحميل الملف

  Future<void> _verifyFileExists() async {
    final BookModel? book = _book;
    if (book == null) {
      return;
    }
    final bool exists = await _fileService.exists(book.filePath);
    if (!mounted) {
      return;
    }
    if (!exists) {
      setState(() => _fileMissing = true);
    }
  }

  void _handleDocumentLoaded(PdfDocumentLoadedDetails details) {
    final BookModel? book = _book;
    if (book == null) {
      return;
    }
    final int total = _controller.pageCount;
    final int target = (widget.initialPage ?? book.lastPage).clamp(1, total < 1 ? 1 : total);

    setState(() {
      _documentLoaded = true;
      _loadError = null;
      _totalPages = total < 1 ? 1 : total;
      _currentPage = target;
    });

    // ننتظر إطاراً واحداً حتى يصبح المتحكم جاهزاً لاستقبال jumpToPage.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _jumpTo(target, persist: false);
      unawaited(_applyPendingRemovals());
      if (book.totalPages != total && total > 0) {
        book.totalPages = total;
        unawaited(_library.saveBook(book));
      }
    });
  }

  void _handleDocumentLoadFailed(PdfDocumentLoadFailedDetails details) {
    if (!mounted) {
      return;
    }
    setState(() {
      _documentLoaded = false;
      _loadError = details.description;
    });
  }

  void _handlePageChanged(PdfPageChangedDetails details) {
    if (!mounted) {
      return;
    }
    setState(() => _currentPage = details.newPageNumber);
    _scheduleProgressSave();
  }

  // ------------------------------------------------------- التنقل والتكبير

  void _jumpTo(int page, {bool persist = true}) {
    final int target = page.clamp(1, _totalPages);
    try {
      _controller.jumpToPage(target);
    } catch (error) {
      debugPrint('jumpToPage($target) failed: $error');
      return;
    }
    if (mounted) {
      setState(() => _currentPage = target);
    }
    if (persist) {
      _scheduleProgressSave();
    }
  }

  void _handleZoom(double delta) {
    final double next = (_controller.zoomLevel + delta).clamp(1.0, 5.0);
    _controller.zoomLevel = next;
  }

  // ------------------------------------------------- حفظ تقدم القراءة

  void _scheduleProgressSave() {
    _progressDebounce?.cancel();
    _progressDebounce = Timer(
      const Duration(milliseconds: 700),
      () => unawaited(_persistProgress()),
    );
  }

  Future<void> _persistProgress() async {
    final BookModel? book = _book;
    if (book == null) {
      return;
    }
    await _library.saveReadingProgress(book, _currentPage);
  }

  // ------------------------------------------------------- تحديد النص

  void _handleTextSelectionChanged(PdfTextSelectionChangedDetails details) {
    final String? selected = details.selectedText;
    final Rect? region = details.globalSelectedRegion;

    if (selected == null || selected.trim().isEmpty || region == null) {
      _selection = null;
      _removeSelectionMenu();
      return;
    }

    _selection = details;
    _removeSelectionMenu();
    _showSelectionMenu(region);
  }

  void _removeSelectionMenu() {
    if (_selectionMenu != null) {
      _selectionMenu!.remove();
      _selectionMenu = null;
    }
  }

  /// يرسم قائمة السياق قرب النص المحدد مع ضمان بقائها داخل الشاشة.
  void _showSelectionMenu(Rect region) {
    final Size screen = MediaQuery.of(context).size;
    final double topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;
    const double menuWidth = 264;
    const double menuHeight = 58;

    double left = region.center.dx - menuWidth / 2;
    final double maxLeft = screen.width - menuWidth - 12;
    left = left.clamp(12.0, maxLeft < 12 ? 12.0 : maxLeft);

    double top = region.top - menuHeight - 12;
    if (top < topPadding + 8) {
      top = region.bottom + 12;
    }
    if (top + menuHeight > screen.height - 24) {
      top = screen.height - menuHeight - 64;
    }

    _selectionMenu = OverlayEntry(
      builder: (BuildContext overlayContext) => Positioned(
        left: left,
        top: top,
        width: menuWidth,
        child: ColorPickerMenu(
          onColorSelected: (int colorIndex) {
            unawaited(_createHighlight(colorIndex: colorIndex));
          },
          onCopy: () => unawaited(_copySelection()),
          onNote: () => unawaited(_createHighlightWithNote()),
        ),
      ),
    );

    Overlay.of(context, rootOverlay: true).insert(_selectionMenu!);
  }

  /// يبني التظليل ويحفظه في Hive + يرسُمه داخل ملف PDF.
  Future<void> _createHighlight({required int colorIndex, String? note}) async {
    final BookModel? book = _book;
    final PdfTextSelectionChangedDetails? details = _selection;
    if (book == null || details == null) {
      return;
    }

    final String text = (details.selectedText ?? '').trim();
    final List<PdfTextLine> lines =
        _viewerKey.currentState?.getSelectedTextLines() ?? <PdfTextLine>[];

    if (text.isEmpty || lines.isEmpty) {
      _removeSelectionMenu();
      if (mounted) {
        showInfoSnackBar(context, AppLocalizations.of(context).selectionFailed);
      }
      return;
    }

    try {
      // 1) حفظ الاقتباس نصياً (مصدر الحقيقة للاقتباسات والملاحظات).
      final HighlightModel highlight = await _highlights.add(
        bookId: book.id,
        bookTitle: book.title,
        text: text,
        pageNumber: lines.first.pageNumber,
        colorIndex: colorIndex,
        note: note,
      );

      // 2) رسم التظليل على الصفحة باستخدام إحداثيات الأسطر المحددة نفسها.
      //    نضع معرّف الاقتباس في `name` حتى نستطيع إيجاده لاحقاً عند الحذف.
      final HighlightAnnotation annotation =
          HighlightAnnotation(textBoundsCollection: lines)
            ..color = AppColors.highlightColor(colorIndex)
            ..opacity = AppColors.highlightOpacity
            ..name = highlight.id
            ..author = 'Mikasa'
            ..subject = note ?? '';

      _controller.addAnnotation(annotation);
      _controller.clearSelection();
      _selection = null;
      _removeSelectionMenu();

      // 3) تثبيت التظليل داخل الملف حتى يظهر بعد إعادة فتح الكتاب.
      await _persistAnnotations();

      if (!mounted) {
        return;
      }
      final AppLocalizations l10n = AppLocalizations.of(context);
      showInfoSnackBar(
        context,
        l10n.highlightSaved,
        action: SnackBarAction(
          label: l10n.actionAddNote,
          onPressed: () => unawaited(_editNote(highlight)),
        ),
      );
    } catch (error) {
      debugPrint('_createHighlight failed: $error');
      if (mounted) {
        showFailureSnackBar(context, FailureCode.unknown);
      }
    }
  }

  Future<void> _createHighlightWithNote() async {
    final String? note = await showNoteEditorSheet(context);
    if (!mounted || note == null) {
      return;
    }
    await _createHighlight(colorIndex: 0, note: note.trim().isEmpty ? null : note.trim());
  }

  Future<void> _editNote(HighlightModel highlight) async {
    final String? note = await showNoteEditorSheet(context, initialNote: highlight.note);
    if (!mounted || note == null) {
      return;
    }
    await _highlights.updateNote(highlight, note);
  }

  Future<void> _copySelection() async {
    final String text = (_selection?.selectedText ?? '').trim();
    if (text.isEmpty) {
      return;
    }
    await Clipboard.setData(ClipboardData(text: text));
    _controller.clearSelection();
    _selection = null;
    _removeSelectionMenu();
    if (!mounted) {
      return;
    }
    showInfoSnackBar(context, AppLocalizations.of(context).copySuccess);
  }

  // ------------------------------------------------- تثبيت التظليلات في الملف

  /// يحفظ المستند (مع التظليلات) ويعيد كتابته في ملف PDF المحلي.
  Future<void> _persistAnnotations() async {
    final BookModel? book = _book;
    if (book == null) {
      return;
    }
    try {
      final List<int> bytes = await _controller.saveDocument();
      await _fileService.writePdfBytes(book.filePath, bytes);
    } catch (error) {
      debugPrint('_persistAnnotations failed: $error');
      if (mounted) {
        showInfoSnackBar(context, AppLocalizations.of(context).highlightSaveFailed);
      }
    }
  }

  /// ينفّذ عمليات الحذف التي حصلت من شاشة الاقتباسات (حيث لا يكون العارض مفتوحاً).
  Future<void> _applyPendingRemovals() async {
    final List<String> pending = _database.pendingRemovals();
    if (pending.isEmpty) {
      return;
    }
    try {
      final List<Annotation> annotations = _controller.getAnnotations();
      bool changed = false;
      for (final Annotation annotation in annotations) {
        final String? name = annotation.name;
        if (name != null && pending.contains(name)) {
          _controller.removeAnnotation(annotation);
          changed = true;
        }
      }
      await _database.clearPendingRemovals();
      if (changed) {
        await _persistAnnotations();
      }
    } catch (error) {
      debugPrint('_applyPendingRemovals failed: $error');
    }
  }

  // ------------------------------------------------------------- التنقل

  Future<void> _openHighlights() async {
    final int? page = await context.push<int>(AppRoutes.bookHighlights(widget.bookId));
    if (!mounted) {
      return;
    }
    if (page != null) {
      _jumpTo(page);
    }
    // قد يكون المستخدم حذف اقتباسات هناك: ننظّف رسمها من الصفحات.
    await _applyPendingRemovals();
  }

  Future<void> _toggleNightMode() async {
    await _settings.setNightReadingMode(!_settings.nightReadingMode);
  }

  void _retry() {
    setState(() {
      _loadError = null;
      _documentLoaded = false;
      _viewerVersion++;
    });
  }

  // --------------------------------------------------------------- الواجهة

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final BookModel? book = _book;

    if (book == null) {
      return _MessageScaffold(
        icon: Icons.menu_book_outlined,
        title: l10n.bookNotFoundTitle,
        message: l10n.bookNotFoundBody,
        actionLabel: l10n.backToLibrary,
        onAction: () => context.go(AppRoutes.library),
      );
    }

    if (_fileMissing) {
      return _MessageScaffold(
        icon: Icons.file_present_outlined,
        title: l10n.fileMissingTitle,
        message: l10n.fileMissingBody,
        actionLabel: l10n.removeFromLibrary,
        onAction: () async {
          await _library.deleteBook(book, deleteHighlights: false);
          if (context.mounted) {
            context.go(AppRoutes.library);
          }
        },
      );
    }

    final bool nightMode = context.watch<SettingsProvider>().nightReadingMode;
    final int highlightCount = context.watch<HighlightsProvider>().countForBook(book.id);
    final bool loadFailed = _loadError != null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        titleSpacing: 0,
        title: Row(
          children: <Widget>[
            Hero(
              tag: BookCard.heroTag(book.id),
              child: Container(
                width: 30,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(7),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      Theme.of(context).colorScheme.primary,
                      AppColors.secondary.withValues(alpha: 0.85),
                    ],
                  ),
                ),
                child: const Icon(Icons.menu_book_rounded, size: 16, color: Colors.white),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    book.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  Text(
                    l10n.bookPageOf(_currentPage, _totalPages),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.55),
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            tooltip: l10n.allQuotesTitle,
            onPressed: _openHighlights,
            icon: Badge(
              isLabelVisible: highlightCount > 0,
              label: Text('$highlightCount'),
              child: const Icon(Icons.format_quote_rounded),
            ),
          ),
          IconButton(
            tooltip: nightMode ? l10n.readerNightModeOff : l10n.readerNightModeOn,
            onPressed: () => unawaited(_toggleNightMode()),
            icon: Icon(nightMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
          ),
          PopupMenuButton<String>(
            tooltip: '',
            onSelected: (String value) {
              switch (value) {
                case 'zoom_in':
                  _handleZoom(0.5);
                case 'zoom_out':
                  _handleZoom(-0.5);
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'zoom_in',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.zoom_in_rounded),
                  title: Text(l10n.readerZoomIn),
                ),
              ),
              PopupMenuItem<String>(
                value: 'zoom_out',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.zoom_out_rounded),
                  title: Text(l10n.readerZoomOut),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: loadFailed
                ? _MessageBody(
                    icon: Icons.error_outline_rounded,
                    title: l10n.readerLoadFailedTitle,
                    message: l10n.readerLoadFailedBody,
                    actionLabel: l10n.actionRetry,
                    onAction: _retry,
                  )
                : Stack(
                    children: <Widget>[
                      _buildViewer(book, nightMode),
                      if (!_documentLoaded)
                        ColoredBox(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                const CircularProgressIndicator(),
                                const SizedBox(height: 14),
                                Text(l10n.readerLoading),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
          if (!loadFailed)
            PageNavigatorBar(
              currentPage: _currentPage,
              totalPages: _totalPages,
              onJump: _jumpTo,
            ),
        ],
      ),
    );
  }

  Widget _buildViewer(BookModel book, bool nightMode) {
    return ColorFiltered(
      colorFilter: ColorFilter.matrix(nightMode ? _invertMatrix : _identityMatrix),
      child: KeyedSubtree(
        key: ValueKey<int>(_viewerVersion),
        child: SfPdfViewer.file(
          File(book.filePath),
          key: _viewerKey,
          controller: _controller,
          pageLayoutMode: PdfPageLayoutMode.continuous,
          scrollDirection: PdfScrollDirection.vertical,
          canShowScrollHead: false,
          canShowTextSelectionMenu: false,
          enableTextSelection: true,
          onDocumentLoaded: _handleDocumentLoaded,
          onDocumentLoadFailed: _handleDocumentLoadFailed,
          onPageChanged: _handlePageChanged,
          onTextSelectionChanged: _handleTextSelectionChanged,
          // لمس أي مكان في الصفحة يُخفي قائمة التظليل.
          onTap: (PdfGestureDetails details) {
            _selection = null;
            _removeSelectionMenu();
          },
        ),
      ),
    );
  }
}

/// شاشة رسالة كاملة (كتاب غير موجود / ملف مفقود).
class _MessageScaffold extends StatelessWidget {
  const _MessageScaffold({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.canPop() ? context.pop() : context.go(AppRoutes.library),
        ),
      ),
      body: _MessageBody(
        icon: icon,
        title: title,
        message: message,
        actionLabel: actionLabel,
        onAction: onAction,
      ),
    );
  }
}

/// جسم رسالة مع أيقونة وزر إجراء.
class _MessageBody extends StatelessWidget {
  const _MessageBody({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 54, color: theme.colorScheme.error),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}
