import 'package:flutter/foundation.dart';
import 'package:mikasa/core/utils/app_failure.dart';
import 'package:mikasa/models/book_model.dart';
import 'package:mikasa/services/database_service.dart';
import 'package:mikasa/services/file_service.dart';

/// حالة المكتبة: قائمة الكتب، الاستيراد، الحذف، وحفظ تقدم القراءة.
class LibraryProvider extends ChangeNotifier {
  LibraryProvider({
    required DatabaseService database,
    required FileService fileService,
  })  : _database = database,
        _fileService = fileService;

  final DatabaseService _database;
  final FileService _fileService;

  final List<BookModel> _books = <BookModel>[];
  bool _isLoading = true;
  bool _isImporting = false;
  FailureCode? _lastFailure;

  List<BookModel> get books => List<BookModel>.unmodifiable(_books);
  bool get isLoading => _isLoading;
  bool get isImporting => _isImporting;
  bool get isEmpty => _books.isEmpty;
  FailureCode? get lastFailure => _lastFailure;

  BookModel? bookById(String id) {
    for (final BookModel book in _books) {
      if (book.id == id) {
        return book;
      }
    }
    return null;
  }

  Future<void> loadBooks() async {
    _isLoading = true;
    _lastFailure = null;
    notifyListeners();

    try {
      final List<BookModel> loaded = _database.getAllBooks();
      _books
        ..clear()
        ..addAll(loaded);
    } catch (error) {
      _lastFailure = FailureCode.unknown;
      debugPrint('LibraryProvider.loadBooks: $error');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// يستورد ملف PDF جديداً ويضيفه للمكتبة.
  ///
  /// يعيد الكتاب عند النجاح، أو `null` إذا أُلغيت العملية/فشلت
  /// (سبب الفشل متاح عبر [lastFailure]).
  Future<BookModel?> importBook() async {
    _isImporting = true;
    _lastFailure = null;
    notifyListeners();

    try {
      final ImportedPdf? imported = await _fileService.importPdf();
      if (imported == null) {
        return null; // ألغى المستخدم
      }

      // إعادة استيراد نفس الملف لا تُنشئ نسخة مكررة في المكتبة.
      final BookModel? existing = _database.getBook(imported.id);
      final BookModel book = existing != null
          ? existing.copyWith(
              lastOpened: DateTime.now(),
              totalPages: imported.totalPages > 0 ? imported.totalPages : existing.totalPages,
            )
          : BookModel(
              id: imported.id,
              title: imported.title,
              filePath: imported.filePath,
              totalPages: imported.totalPages,
              lastOpened: DateTime.now(),
            );

      await _database.saveBook(book);
      await loadBooks();
      return book;
    } on AppFailure catch (failure) {
      _lastFailure = failure.code;
      return null;
    } catch (error) {
      debugPrint('LibraryProvider.importBook: $error');
      _lastFailure = FailureCode.unknown;
      return null;
    } finally {
      _isImporting = false;
      notifyListeners();
    }
  }

  /// حذف كتاب من المكتبة، مع خيار حذف اقتباساته أيضاً.
  Future<void> deleteBook(BookModel book, {required bool deleteHighlights}) async {
    try {
      await _database.deleteBook(book.id);
      if (deleteHighlights) {
        await _database.deleteHighlightsForBook(book.id);
      }
      await _fileService.deleteBookFile(book.filePath);
    } catch (error) {
      debugPrint('LibraryProvider.deleteBook: $error');
      _lastFailure = FailureCode.unknown;
    }

    _books.removeWhere((BookModel item) => item.id == book.id);
    notifyListeners();
  }

  /// حفظ آخر صفحة وصل إليها المستخدم (تُستدعى بتأخير بسيط من شاشة القارئ).
  Future<void> saveReadingProgress(BookModel book, int page) async {
    if (book.lastPage == page) {
      // لا نكتب في قاعدة البيانات بلا داعٍ (استهلاك بطارية/قرص أقل).
      book.lastOpened = DateTime.now();
      return;
    }
    book.lastPage = page;
    book.lastOpened = DateTime.now();
    await _database.saveBook(book);
    notifyListeners();
  }

  /// تحديث بيانات الكتاب (مثلاً إجمالي الصفحات بعد أول فتح).
  Future<void> saveBook(BookModel book) async {
    try {
      await _database.saveBook(book);
      notifyListeners();
    } catch (error) {
      debugPrint('LibraryProvider.saveBook: $error');
    }
  }
}
