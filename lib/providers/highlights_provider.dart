import 'package:flutter/foundation.dart';
import 'package:mikasa/core/utils/id_utils.dart';
import 'package:mikasa/models/highlight_model.dart';
import 'package:mikasa/services/database_service.dart';

/// حالة الاقتباسات: القراءة، الإضافة، التعديل، الحذف، والبحث/الفلترة.
class HighlightsProvider extends ChangeNotifier {
  HighlightsProvider({required DatabaseService database}) : _database = database;

  final DatabaseService _database;

  final List<HighlightModel> _items = <HighlightModel>[];
  bool _isLoading = true;

  bool get isLoading => _isLoading;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      final List<HighlightModel> loaded = _database.getAllHighlights();
      _items
        ..clear()
        ..addAll(loaded);
    } catch (error) {
      debugPrint('HighlightsProvider.load: $error');
    }
    _isLoading = false;
    notifyListeners();
  }

  /// اقتباسات كتاب معيّن، أو كل الاقتباسات عند تمرير `null`.
  List<HighlightModel> forBook(String? bookId) {
    if (bookId == null) {
      return List<HighlightModel>.unmodifiable(_items);
    }
    return _items
        .where((HighlightModel highlight) => highlight.bookId == bookId)
        .toList(growable: false);
  }

  int countForBook(String bookId) {
    return _items.where((HighlightModel highlight) => highlight.bookId == bookId).length;
  }

  /// بحث نصي + فلترة باللون (تُستخدم في شاشة الاقتباسات).
  List<HighlightModel> filter({
    String? bookId,
    int? colorIndex,
    String query = '',
  }) {
    final String normalizedQuery = query.trim().toLowerCase();
    return forBook(bookId).where((HighlightModel highlight) {
      final bool matchesColor = colorIndex == null || highlight.colorIndex == colorIndex;
      final bool matchesQuery = normalizedQuery.isEmpty ||
          highlight.text.toLowerCase().contains(normalizedQuery) ||
          (highlight.note ?? '').toLowerCase().contains(normalizedQuery);
      return matchesColor && matchesQuery;
    }).toList(growable: false);
  }

  /// إضافة اقتباس جديد. تُعيد النموذج (بمعرّفه) حتى يربطه القارئ بالتظليل المرسوم.
  Future<HighlightModel> add({
    required String bookId,
    required String bookTitle,
    required String text,
    required int pageNumber,
    required int colorIndex,
    String? note,
  }) async {
    final HighlightModel highlight = HighlightModel(
      id: IdUtils.newId(),
      bookId: bookId,
      bookTitle: bookTitle,
      text: text,
      pageNumber: pageNumber,
      colorIndex: colorIndex,
      note: note,
      createdAt: DateTime.now(),
    );

    await _database.saveHighlight(highlight);
    _items.add(highlight);
    notifyListeners();
    return highlight;
  }

  Future<void> updateNote(HighlightModel highlight, String? note) async {
    final String? normalized = (note == null || note.trim().isEmpty) ? null : note.trim();
    final HighlightModel updated = highlight.copyWith(
      note: normalized,
      clearNote: normalized == null,
    );

    await _database.saveHighlight(updated);
    final int index = _items.indexWhere((HighlightModel item) => item.id == highlight.id);
    if (index != -1) {
      _items[index] = updated;
    }
    notifyListeners();
  }

  Future<void> updateColor(HighlightModel highlight, int colorIndex) async {
    final HighlightModel updated = highlight.copyWith(colorIndex: colorIndex);
    await _database.saveHighlight(updated);
    final int index = _items.indexWhere((HighlightModel item) => item.id == highlight.id);
    if (index != -1) {
      _items[index] = updated;
    }
    notifyListeners();
  }

  /// حذف اقتباس.
  ///
  /// نضيف معرّفه إلى قائمة "الحذف المؤجَّل" لأن مسح التظليل من ملف PDF يحتاج
  /// العارض مفتوحاً؛ يُنفَّذ ذلك تلقائياً في أول فتح قادم للكتاب.
  Future<void> delete(HighlightModel highlight) async {
    await _database.deleteHighlight(highlight.id);
    await _database.addPendingRemoval(highlight.id);
    _items.removeWhere((HighlightModel item) => item.id == highlight.id);
    notifyListeners();
  }
}
