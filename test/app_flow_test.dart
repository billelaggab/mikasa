import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mikasa/core/constants/app_strings.dart';
import 'package:mikasa/models/book_model.dart';
import 'package:mikasa/models/highlight_model.dart';
import 'package:mikasa/providers/highlights_provider.dart';
import 'package:mikasa/providers/library_provider.dart';
import 'package:mikasa/providers/settings_provider.dart';
import 'package:mikasa/screens/library_screen.dart';
import 'package:mikasa/services/database_service.dart';
import 'package:mikasa/services/file_service.dart';
import 'package:provider/provider.dart';

/// اختبارات طبقة البيانات + اختبار واجهة بسيط لشاشة المكتبة
/// (تعمل دون جهاز: قاعدة البيانات في مجلد مؤقت وHive.init بدل initFlutter).
void main() {
  late Directory tempDir;
  late DatabaseService database;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('mikasa_test_');
    database = DatabaseService();
    await database.init(hivePathOverride: tempDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  setUp(() async {
    await Hive.box<BookModel>('books').clear();
    await Hive.box<HighlightModel>('highlights').clear();
    await Hive.box<dynamic>('pending_removals').clear();
    await Hive.box<dynamic>('settings').clear();
  });

  group('DatabaseService', () {
    test('يحفظ الكتب ويرتبها حسب آخر فتح', () async {
      final BookModel older = BookModel(
        id: 'a',
        title: 'قديم',
        filePath: '/tmp/a.pdf',
        lastOpened: DateTime(2026, 1, 1),
      );
      final BookModel newer = BookModel(
        id: 'b',
        title: 'جديد',
        filePath: '/tmp/b.pdf',
        lastOpened: DateTime(2026, 6, 1),
      );

      await database.saveBook(older);
      await database.saveBook(newer);

      final List<BookModel> books = database.getAllBooks();
      expect(books.map((BookModel book) => book.id), <String>['b', 'a']);
      expect(database.getBook('a')?.title, 'قديم');
    });

    test('يعدّ الاقتباسات ويحذفها لكتاب محدد فقط', () async {
      final HighlightsProvider provider = HighlightsProvider(database: database);
      await provider.load();

      await provider.add(
        bookId: 'book-1',
        bookTitle: 'الأول',
        text: 'اقتباس أول',
        pageNumber: 3,
        colorIndex: 0,
      );
      await provider.add(
        bookId: 'book-1',
        bookTitle: 'الأول',
        text: 'اقتباس ثانٍ',
        pageNumber: 9,
        colorIndex: 2,
        note: 'ملاحظة',
      );
      await provider.add(
        bookId: 'book-2',
        bookTitle: 'الثاني',
        text: 'اقتباس آخر',
        pageNumber: 1,
        colorIndex: 1,
      );

      expect(provider.countForBook('book-1'), 2);
      expect(provider.countForBook('book-2'), 1);

      // فلترة باللون والبحث النصي
      expect(provider.filter(bookId: 'book-1', colorIndex: 2), hasLength(1));
      expect(provider.filter(query: 'آخر'), hasLength(1));
      expect(provider.filter(bookId: 'book-1', query: 'ملاحظة'), hasLength(1));

      await database.deleteHighlightsForBook('book-1');
      await provider.load();
      expect(provider.countForBook('book-1'), 0);
      expect(provider.countForBook('book-2'), 1);
    });

    test('يسجّل الحذف المؤجَّل لتظليل محذوف من الواجهة', () async {
      final HighlightsProvider provider = HighlightsProvider(database: database);
      await provider.load();
      final highlight = await provider.add(
        bookId: 'book-9',
        bookTitle: 'كتاب',
        text: 'نص',
        pageNumber: 2,
        colorIndex: 3,
      );

      await provider.delete(highlight);
      expect(provider.forBook('book-9'), isEmpty);
      expect(database.pendingRemovals(), <String>[highlight.id]);

      await database.clearPendingRemovals();
      expect(database.pendingRemovals(), isEmpty);
    });

    test('يحفظ الإعدادات ويقرأها', () async {
      await database.writeSetting('theme_mode', 'dark');
      await database.writeSetting('night_reading_mode', true);

      expect(database.readString('theme_mode'), 'dark');
      expect(database.readBool('night_reading_mode'), isTrue);

      final SettingsProvider settings = SettingsProvider(database)..load();
      expect(settings.themeMode, ThemeMode.dark);
      expect(settings.nightReadingMode, isTrue);
      expect(settings.locale.languageCode, 'ar');
    });
  });

  group('LibraryProvider', () {
    test('يعيد قائمة فارغة عند عدم وجود كتب', () async {
      final LibraryProvider library = LibraryProvider(
        database: database,
        fileService: FileService(),
      );
      await library.loadBooks();

      expect(library.isLoading, isFalse);
      expect(library.isEmpty, isTrue);
      expect(library.bookById('none'), isNull);
    });

    test('يحفظ تقدم القراءة دون تكرار الكتاب', () async {
      final LibraryProvider library = LibraryProvider(
        database: database,
        fileService: FileService(),
      );
      final BookModel book = BookModel(
        id: 'p1',
        title: 'كتاب',
        filePath: '/tmp/p1.pdf',
        totalPages: 100,
        lastOpened: DateTime.now(),
      );
      await database.saveBook(book);
      await library.loadBooks();

      await library.saveReadingProgress(library.bookById('p1')!, 42);
      expect(database.getBook('p1')?.lastPage, 42);
      expect(library.books, hasLength(1));
    });
  });

  testWidgets('شاشة المكتبة تعرض الحالة الفارغة ثم بطاقة الكتاب', (
    WidgetTester tester,
  ) async {
    final LibraryProvider library = LibraryProvider(
      database: database,
      fileService: FileService(),
    );
    final HighlightsProvider highlights = HighlightsProvider(database: database);

    // أي عملية I/O حقيقية (Hive/ملفات) يجب أن تجري داخل runAsync،
    // لأن testWidgets يعمل بزمن وهمي لا تُكتمل فيه العمليات غير المتزامنة.
    await tester.runAsync(() async {
      await library.loadBooks();
      await highlights.load();
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<DatabaseService>.value(value: database),
          Provider<FileService>.value(value: FileService()),
          ChangeNotifierProvider<SettingsProvider>.value(
            value: SettingsProvider(database)..load(),
          ),
          ChangeNotifierProvider<LibraryProvider>.value(value: library),
          ChangeNotifierProvider<HighlightsProvider>.value(value: highlights),
        ],
        child: const MaterialApp(
          locale: Locale('ar'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: <LocalizationsDelegate<dynamic>>[
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: LibraryScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('مكتبتك فارغة'), findsOneWidget);

    await tester.runAsync(() async {
      await database.saveBook(
        BookModel(
          id: 'ui-1',
          title: 'كتاب واجهة',
          filePath: '/tmp/ui-1.pdf',
          totalPages: 300,
          lastPage: 30,
          lastOpened: DateTime.now(),
        ),
      );
      await library.loadBooks();
    });
    await tester.pumpAndSettle();

    expect(find.text('كتاب واجهة'), findsOneWidget);
    expect(find.textContaining('30'), findsWidgets);
  });
}
