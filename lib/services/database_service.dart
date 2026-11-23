import 'package:hive_flutter/hive_flutter.dart';
import 'package:mikasa/models/book_model.dart';
import 'package:mikasa/models/highlight_model.dart';

/// طبقة الوصول الوحيدة إلى قاعدة البيانات (Hive).
///
/// كل عمليات القراءة/الكتابة تمر من هنا، فلا تعرف الشاشات أو الـ Providers
/// أي شيء عن Hive. هذا يسهّل استبدال قاعدة البيانات لاحقاً (SOLID / DIP).
class DatabaseService {
  static const String _booksBoxName = 'books';
  static const String _highlightsBoxName = 'highlights';
  static const String _pendingBoxName = 'pending_removals';
  static const String _settingsBoxName = 'settings';

  /// مفتاح واحد يحتوي قائمة معرّفات التظليلات المحذوفة من الواجهة
  /// والتي يجب محو رسمها من ملف PDF في أول فتح قادم للكتاب.
  static const String _pendingRemovalsKey = 'highlight_ids';

  late final Box<BookModel> _books;
  late final Box<HighlightModel> _highlights;
  late final Box<dynamic> _pending;
  late final Box<dynamic> _settings;

  bool _isInitialized = false;

  /// تهيئة Hive وفتح الصناديق. تُستدعى مرة واحدة من `main()`.
  ///
  /// [hivePathOverride] مخصّص للاختبارات (Hive.init بمسار مؤقت) بدل
  /// `initFlutter` الذي يحتاج إضافات المنصة.
  Future<void> init({String? hivePathOverride}) async {
    if (_isInitialized) {
      return;
    }
    if (hivePathOverride != null) {
      Hive.init(hivePathOverride);
    } else {
      await Hive.initFlutter('mikasa');
    }

    // Adapters مكتوبة يدوياً، لذا لا نحتاج build_runner إطلاقاً.
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(BookModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(HighlightModelAdapter());
    }

    _books = await Hive.openBox<BookModel>(_booksBoxName);
    _highlights = await Hive.openBox<HighlightModel>(_highlightsBoxName);
    _pending = await Hive.openBox<dynamic>(_pendingBoxName);
    _settings = await Hive.openBox<dynamic>(_settingsBoxName);

    _isInitialized = true;
  }

  // ---------------------------------------------------------------- الكتب

  /// كل الكتب مرتبة حسب آخر فتح (الأحدث أولاً).
  List<BookModel> getAllBooks() {
    final List<BookModel> books = _books.values.toList()
      ..sort((BookModel a, BookModel b) => b.lastOpened.compareTo(a.lastOpened));
    return books;
  }

  BookModel? getBook(String id) => _books.get(id);

  Future<void> saveBook(BookModel book) => _books.put(book.id, book);

  Future<void> deleteBook(String id) => _books.delete(id);

  // ------------------------------------------------------------- الاقتباسات

  /// كل الاقتباسات مرتبة حسب الصفحة ثم زمن الإنشاء.
  List<HighlightModel> getAllHighlights() {
    return _highlights.values.toList()..sort(_compareHighlights);
  }

  List<HighlightModel> getHighlightsForBook(String bookId) {
    return getAllHighlights()
        .where((HighlightModel highlight) => highlight.bookId == bookId)
        .toList();
  }

  int highlightCountForBook(String bookId) {
    return _highlights.values
        .where((HighlightModel highlight) => highlight.bookId == bookId)
        .length;
  }

  Future<void> saveHighlight(HighlightModel highlight) =>
      _highlights.put(highlight.id, highlight);

  Future<void> deleteHighlight(String id) => _highlights.delete(id);

  Future<void> deleteHighlightsForBook(String bookId) async {
    final List<String> ids = _highlights.values
        .where((HighlightModel highlight) => highlight.bookId == bookId)
        .map((HighlightModel highlight) => highlight.id)
        .toList();
    if (ids.isNotEmpty) {
      await _highlights.deleteAll(ids);
    }
  }

  int _compareHighlights(HighlightModel a, HighlightModel b) {
    final int byPage = a.pageNumber.compareTo(b.pageNumber);
    if (byPage != 0) {
      return byPage;
    }
    return a.createdAt.compareTo(b.createdAt);
  }

  // ------------------------------------------- عمليات مؤجَّلة على ملف PDF

  List<String> pendingRemovals() {
    final dynamic raw = _pending.get(_pendingRemovalsKey);
    if (raw is List) {
      return raw.map((dynamic item) => item.toString()).toList();
    }
    return <String>[];
  }

  Future<void> addPendingRemoval(String highlightId) async {
    final List<String> ids = pendingRemovals();
    if (ids.contains(highlightId)) {
      return;
    }
    ids.add(highlightId);
    await _pending.put(_pendingRemovalsKey, ids);
  }

  Future<void> clearPendingRemovals() => _pending.delete(_pendingRemovalsKey);

  // -------------------------------------------------------------- الإعدادات

  String? readString(String key) {
    final dynamic value = _settings.get(key);
    return value is String ? value : null;
  }

  bool? readBool(String key) {
    final dynamic value = _settings.get(key);
    return value is bool ? value : null;
  }

  Future<void> writeSetting(String key, Object? value) => _settings.put(key, value);
}
