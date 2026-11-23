/// أكواد الأعطال التي يمكن أن تحصل أثناء استيراد/قراءة الملفات.
///
/// نفصل "الكود" عن "الرسالة" حتى تبقى طبقة الخدمات مستقلة عن اللغة،
/// وتتولّى طبقة الواجهة ترجمة الكود إلى رسالة مفهومة للمستخدم.
enum FailureCode {
  /// الملف ليس PDF صالحاً أو أنه تالف.
  invalidPdf,

  /// لم يمنح المستخدم صلاحية قراءة الملف.
  permissionDenied,

  /// الملف موجود في قاعدة البيانات لكنه محذوف من ذاكرة الهاتف.
  fileMissing,

  /// فشل غير معروف (خطأ نظام ملفات، ذاكرة ممتلئة...).
  unknown,
}

/// استثناء يحمل كود عطل معروفاً، لتتمكن الواجهة من عرض رسالة واضحة.
class AppFailure implements Exception {
  const AppFailure(this.code, {this.details});

  final FailureCode code;
  final Object? details;

  @override
  String toString() => 'AppFailure(code: $code, details: $details)';
}
