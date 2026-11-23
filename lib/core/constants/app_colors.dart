import 'package:flutter/material.dart';

/// ألوان التطبيق المركزية.
///
/// قاعدة واحدة: الشاشات لا تكتب أكواداً لونية مباشرة، بل تستخدم هذه القيم
/// (مبدأ DRY + سهولة تغيير الهوية البصرية لاحقاً).
class AppColors {
  const AppColors._();

  /// اللون الأساسي المقترح في المواصفات: بنفسجي هادئ.
  static const Color primary = Color(0xFF6C63FF);

  /// نسخة أفتح من اللون الأساسي للاستخدام على الخلفيات الداكنة.
  static const Color primaryLight = Color(0xFF9A94FF);

  /// اللون الثانوي (أخضر زيتوني).
  static const Color secondary = Color(0xFF5B8C51);

  // --- خلفيات الوضع الليلي ---
  static const Color darkBackground = Color(0xFF0D0E15);
  static const Color darkSurface = Color(0xFF171825);
  static const Color darkSurfaceVariant = Color(0xFF22243A);

  // --- خلفيات الوضع النهاري ---
  static const Color lightBackground = Color(0xFFF7F6FB);
  static const Color lightSurface = Color(0xFFFFFFFF);

  // --- ألوان التظليل ---
  // ترتيب هذه القائمة مرتبط مباشرة بالحقل `colorIndex` في HighlightModel،
  // لذلك لا تُعيد ترتيبها بعد إصدار التطبيق.
  static const Color highlightYellow = Color(0xFFFFD54F);
  static const Color highlightGreen = Color(0xFF6BD08A);
  static const Color highlightBlue = Color(0xFF63B3ED);
  static const Color highlightRed = Color(0xFFEF6F6C);

  static const List<Color> highlightColors = <Color>[
    highlightYellow,
    highlightGreen,
    highlightBlue,
    highlightRed,
  ];

  /// يعيد لون التظليل المطابق للفهرس مع حماية من القيم خارج النطاق.
  static Color highlightColor(int index) =>
      highlightColors[index.clamp(0, highlightColors.length - 1)];

  /// الشفافية المستخدمة عند رسم التظليل داخل الصفحة،
  /// حتى يبقى النص مقروءاً تحت اللون.
  static const double highlightOpacity = 0.42;
}
