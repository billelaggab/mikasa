import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mikasa/core/utils/app_failure.dart';

/// ترجمة نصوص التطبيق (عربي/إنجليزي).
///
/// اخترنا كلاساً بأنواع صريحة (getters) بدل ملفات ARB/codegen لأن:
/// - لا يحتاج خطوة بناء إضافية (لا `build_runner`).
/// - أي مفتاح خاطئ يظهر كخطأ ترجمة وقت البناء، لا كنص "key" على الشاشة.
class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  bool get isArabic => locale.languageCode == 'ar';

  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        const AppLocalizations(Locale('ar'));
  }

  /// يختار النص حسب اللغة الحالية.
  String _s(String ar, String en) => isArabic ? ar : en;

  // --- عام ---
  String get appTitle => _s('ميكاسا', 'Mikasa');
  String get librarySubtitle => _s('مكتبتك الخاصة', 'Your private library');
  String get importPdf => _s('استيراد PDF', 'Import PDF');
  String get importing => _s('جارٍ الاستيراد…', 'Importing…');
  String get importSuccess => _s('تمت إضافة الكتاب إلى مكتبتك', 'Book added to your library');

  // --- المكتبة ---
  String get libraryEmptyTitle => _s('مكتبتك فارغة', 'Your library is empty');
  String get libraryEmptyBody => _s(
        'استورد أول ملف PDF وابدأ بتظليل ما يستحق الاحتفاظ به.',
        'Import your first PDF and start highlighting what matters.',
      );
  String bookPages(int count) =>
      isArabic ? '$count صفحة' : (count == 1 ? '1 page' : '$count pages');
  String bookHighlights(int count) => isArabic
      ? '$count اقتباس'
      : (count == 1 ? '1 quote' : '$count quotes');
  String bookLastOpened(String value) => _s('آخر فتح $value', 'Opened $value');
  String bookPageOf(int page, int total) => _s('صفحة $page من $total', 'Page $page of $total');
  String bookProgress(int percent) => _s('$percent٪ مكتمل', '$percent% read');

  // --- القارئ ---
  String get readerLoading => _s('جارٍ تحميل الملف…', 'Loading document…');
  String get readerLoadFailedTitle => _s('تعذّر فتح هذا الملف', 'Could not open this file');
  String get readerLoadFailedBody => _s(
        'قد يكون الملف تالفاً أو محمياً بكلمة مرور. جرّب ملفاً آخر أو أعد استيراده.',
        'The file may be corrupted or password-protected. Try another file or re-import it.',
      );
  String get fileMissingTitle => _s('الملف غير موجود', 'File not found');
  String get fileMissingBody => _s(
        'يبدو أن ملف PDF حُذف أو نُقل من ذاكرة الهاتف. يمكنك إزالته من المكتبة.',
        'The PDF seems to have been deleted or moved. You can remove it from your library.',
      );
  String get removeFromLibrary => _s('إزالة من المكتبة', 'Remove from library');
  String get bookNotFoundTitle => _s('الكتاب غير متاح', 'Book unavailable');
  String get bookNotFoundBody => _s(
        'لا يوجد كتاب مطابق في المكتبة. ربما تم حذفه.',
        'No matching book in the library. It may have been deleted.',
      );
  String get backToLibrary => _s('العودة للمكتبة', 'Back to library');
  String get readerNightModeOn => _s('الوضع الليلي للقراءة', 'Night reading');
  String get readerNightModeOff => _s('الوضع النهاري للقراءة', 'Day reading');
  String get readerZoomIn => _s('تكبير', 'Zoom in');
  String get readerZoomOut => _s('تصغير', 'Zoom out');
  String get readerGoToPage => _s('الانتقال إلى صفحة', 'Go to page');
  String get previousPage => _s('الصفحة السابقة', 'Previous page');
  String get nextPage => _s('الصفحة التالية', 'Next page');
  String get readerPageHint => _s('رقم الصفحة', 'Page number');
  String get readerPageInvalid => _s('رقم صفحة غير صالح', 'Invalid page number');
  String readerPageOfShort(int page, int total) => '$page / $total';

  // --- التظليل ---
  String get colorYellow => _s('تظليل أصفر', 'Yellow highlight');
  String get colorGreen => _s('تظليل أخضر', 'Green highlight');
  String get colorBlue => _s('تظليل أزرق', 'Blue highlight');
  String get colorRed => _s('تظليل أحمر', 'Red highlight');
  String get actionCopy => _s('نسخ النص', 'Copy text');
  String get actionAddNote => _s('إضافة ملاحظة', 'Add note');
  String get copySuccess => _s('تم نسخ النص', 'Text copied');
  String get highlightSaved => _s('تم حفظ الاقتباس', 'Quote saved');
  String get highlightSaveFailed => _s(
        'حُفظ الاقتباس، لكن تعذّر تحديث ملف PDF. سيظهر التظليل في قائمة الاقتباسات.',
        'Quote saved, but the PDF file could not be updated. It will still appear in your quotes.',
      );
  String get selectionFailed => _s(
        'تعذّر تحديد موضع النص داخل الصفحة. جرّب تحديداً أقصر.',
        'Could not locate the selected text on the page. Try a shorter selection.',
      );

  // --- شاشة الاقتباسات ---
  String get allQuotesTitle => _s('كل الاقتباسات', 'All quotes');
  String bookQuotesTitle(String title) => _s('اقتباسات «$title»', 'Quotes from “$title”');
  String get quotesEmptyTitle => _s('لا اقتباسات بعد', 'No quotes yet');
  String get quotesEmptyBody => _s(
        'حدّد أي نص داخل الكتاب ثم اختر لوناً لتظليله، وسيظهر هنا.',
        'Select any text in the book, pick a color, and it will appear here.',
      );
  String get quotesEmptyFilteredTitle => _s('لا نتائج مطابقة', 'No matching quotes');
  String get quotesEmptyFilteredBody => _s(
        'جرّب كلمة بحث أخرى أو أزل فلتر اللون.',
        'Try another search term or clear the color filter.',
      );
  String get quotesSearchHint => _s('ابحث في نصوص الاقتباسات…', 'Search quotes…');
  String get quotesFilterAll => _s('الكل', 'All');
  String quotePage(int page) => _s('صفحة $page', 'Page $page');
  String get goRead => _s('متابعة القراءة', 'Continue reading');
  String get goToLibrary => _s('الذهاب إلى المكتبة', 'Go to library');
  String get actionShare => _s('مشاركة', 'Share');
  String get actionEditNote => _s('تعديل الملاحظة', 'Edit note');
  String get actionDelete => _s('حذف', 'Delete');
  String get shareSubject => _s('اقتباس من ميكاسا', 'A quote from Mikasa');
  String shareSignature(String book) =>
      _s('— من كتاب «$book» عبر تطبيق ميكاسا', '— from “$book” via Mikasa');
  String get deleteQuoteTitle => _s('حذف الاقتباس؟', 'Delete quote?');
  String get deleteQuoteBody => _s(
        'سيُحذف الاقتباس وملاحظته، وسيُمحى التظليل من الصفحة.',
        'The quote and its note will be deleted, and the highlight will be removed from the page.',
      );

  // --- الملاحظات ---
  String get noteSheetTitle => _s('ملاحظة على الاقتباس', 'Quote note');
  String get noteSheetHint => _s('اكتب فكرتك هنا…', 'Write your thought here…');
  String get actionSave => _s('حفظ', 'Save');
  String get actionClear => _s('مسح', 'Clear');
  String get actionCancel => _s('إلغاء', 'Cancel');
  String get actionDeleteAction => _s('حذف', 'Delete');
  String get actionRetry => _s('إعادة المحاولة', 'Retry');

  // --- حذف كتاب ---
  String get deleteBookTitle => _s('حذف الكتاب؟', 'Delete book?');
  String get deleteBookBody => _s(
        'اختر ما تريد حذفه: الكتاب فقط، أو الكتاب مع كل اقتباساته.',
        'Choose what to delete: the book only, or the book with all its quotes.',
      );
  String get deleteBookWithQuotes => _s('حذف الكتاب والاقتباسات', 'Delete book and quotes');
  String get deleteBookKeepQuotes => _s('حذف الكتاب فقط', 'Delete book only');
  String get deleteBookSuccess => _s('تم حذف الكتاب', 'Book deleted');

  // --- الإعدادات ---
  String get settingsTitle => _s('الإعدادات', 'Settings');
  String get settingsAppearance => _s('المظهر', 'Appearance');
  String get settingsThemeSystem => _s('النظام', 'System');
  String get settingsThemeLight => _s('نهاري', 'Light');
  String get settingsThemeDark => _s('ليلي', 'Dark');
  String get settingsLanguage => _s('اللغة', 'Language');
  String get settingsArabic => _s('العربية', 'Arabic');
  String get settingsEnglish => _s('الإنجليزية', 'English');
  String get settingsNightReading => _s('وضع القراءة الليلي', 'Night reading mode');
  String get settingsNightReadingHint => _s(
        'يعكس ألوان صفحات PDF لتقليل إجهاد العين في الظلام.',
        'Inverts PDF page colors to reduce eye strain in the dark.',
      );
  String get settingsAbout => _s('عن التطبيق', 'About');
  String get settingsAboutBody => _s(
        'ميكاسا 1.0.0 — قارئ PDF للقراءة الفعّالة. يعمل دون اتصال، وكل بياناتك محفوظة على جهازك.',
        'Mikasa 1.0.0 — a PDF reader built for active reading. Fully offline, all data stays on your device.',
      );

  // --- الأخطاء ---
  String failureMessage(FailureCode code) {
    switch (code) {
      case FailureCode.invalidPdf:
        return _s(
          'الملف المختار ليس ملف PDF صالحاً أو أنه تالف.',
          'The selected file is not a valid PDF or is corrupted.',
        );
      case FailureCode.permissionDenied:
        return _s(
          'لم يتم منح صلاحية قراءة الملف. امنح الإذن من إعدادات النظام ثم أعد المحاولة.',
          'Permission to read the file was denied. Grant it in system settings and try again.',
        );
      case FailureCode.fileMissing:
        return _s(
          'الملف غير موجود في ذاكرة الهاتف. ربما حُذف أو نُقل.',
          'The file is missing from device storage. It may have been deleted or moved.',
        );
      case FailureCode.unknown:
        return _s(
          'حدث خطأ غير متوقع. أعد المحاولة.',
          'Something went wrong. Please try again.',
        );
    }
  }

  // --- الوقت النسبي ---
  String get timeJustNow => _s('الآن', 'Just now');
  String timeMinutesAgo(int minutes) =>
      _s('قبل $minutes دقيقة', minutes == 1 ? '1 minute ago' : '$minutes minutes ago');
  String timeHoursAgo(int hours) =>
      _s('قبل $hours ساعة', hours == 1 ? '1 hour ago' : '$hours hours ago');
  String timeDaysAgo(int days) =>
      _s('قبل $days يوم', days == 1 ? '1 day ago' : '$days days ago');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales
      .any((Locale supported) => supported.languageCode == locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture<AppLocalizations>(AppLocalizations(locale));

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
