import 'package:flutter_test/flutter_test.dart';
import 'package:mikasa/core/constants/app_colors.dart';
import 'package:mikasa/core/constants/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:mikasa/models/book_model.dart';
import 'package:mikasa/models/highlight_model.dart';

void main() {
  group('BookModel', () {
    final DateTime now = DateTime(2026, 5, 1, 10, 30);

    test('يُرجع نسبة تقدم صحيحة ويحمي من القسمة على صفر', () {
      final BookModel book = BookModel(
        id: 'b1',
        title: 'كتاب',
        filePath: '/tmp/b1.pdf',
        totalPages: 200,
        lastPage: 50,
        lastOpened: now,
      );
      expect(book.progress, closeTo(0.25, 0.0001));

      final BookModel unknownPages = BookModel(
        id: 'b2',
        title: 'كتاب',
        filePath: '/tmp/b2.pdf',
        lastOpened: now,
      );
      expect(unknownPages.progress, 0);
      expect(unknownPages.totalPages, 0);
    });

    test('التحويل إلى خريطة والعودة يفقد أي بيانات', () {
      final BookModel book = BookModel(
        id: 'abc',
        title: 'مقدمة ابن خلدون',
        filePath: '/data/abc.pdf',
        totalPages: 812,
        lastPage: 120,
        lastOpened: now,
        addedAt: now,
      );

      final BookModel restored = BookModel.fromMap(book.toMap());
      expect(restored.id, book.id);
      expect(restored.title, book.title);
      expect(restored.filePath, book.filePath);
      expect(restored.totalPages, book.totalPages);
      expect(restored.lastPage, book.lastPage);
      expect(restored.lastOpened, book.lastOpened);
    });
  });

  group('HighlightModel', () {
    final DateTime created = DateTime(2026, 5, 2, 8);

    HighlightModel build({String? note}) => HighlightModel(
          id: 'h1',
          bookId: 'b1',
          bookTitle: 'كتاب تجريبي',
          text: 'العلم نور',
          pageNumber: 12,
          colorIndex: 2,
          note: note,
          createdAt: created,
        );

    test('hasNote يتعامل مع الملاحظة الفارغة', () {
      expect(build(note: 'فكرة مهمة').hasNote, isTrue);
      expect(build(note: '   ').hasNote, isFalse);
      expect(build().hasNote, isFalse);
    });

    test('copyWith يمكنه مسح الملاحظة صراحةً', () {
      final HighlightModel withNote = build(note: 'ملاحظة');
      final HighlightModel cleared = withNote.copyWith(note: '', clearNote: true);
      expect(cleared.note, isNull);
      expect(cleared.text, withNote.text);
      expect(cleared.colorIndex, withNote.colorIndex);
    });

    test('التحويل إلى خريطة والعودة يحفظ كل الحقول', () {
      final HighlightModel restored = HighlightModel.fromMap(build(note: 'ن').toMap());
      expect(restored.bookTitle, 'كتاب تجريبي');
      expect(restored.pageNumber, 12);
      expect(restored.colorIndex, 2);
      expect(restored.note, 'ن');
      expect(restored.createdAt, created);
    });
  });

  group('AppColors', () {
    test('ألوان التظليل أربعة ومرتبطة بالفهرس بأمان', () {
      expect(AppColors.highlightColors, hasLength(4));
      expect(AppColors.highlightColor(0), AppColors.highlightYellow);
      expect(AppColors.highlightColor(3), AppColors.highlightRed);
      // قيم خارج النطاق لا يجب أن تُسبب استثناء
      expect(AppColors.highlightColor(99), AppColors.highlightRed);
      expect(AppColors.highlightColor(-5), AppColors.highlightYellow);
    });
  });

  group('AppLocalizations', () {
    test('يعرض النصوص العربية والإنجليزية', () {
      const AppLocalizations ar = AppLocalizations(Locale('ar'));
      const AppLocalizations en = AppLocalizations(Locale('en'));

      expect(ar.isArabic, isTrue);
      expect(en.isArabic, isFalse);
      expect(ar.appTitle, 'ميكاسا');
      expect(en.appTitle, 'Mikasa');
      expect(ar.bookPages(3), '3 صفحة');
      expect(en.bookPages(1), '1 page');
      expect(en.shareSignature('Book'), contains('Book'));
    });
  });
}
