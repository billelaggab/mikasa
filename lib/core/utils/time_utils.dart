import 'package:intl/intl.dart';
import 'package:mikasa/core/constants/app_strings.dart';

/// تنسيق زمني مبسّط ("قبل 5 دقائق") مع دعم العربية والإنجليزية.
String formatRelativeTime(AppLocalizations l10n, DateTime date) {
  final Duration diff = DateTime.now().difference(date);

  if (diff.inMinutes < 1) {
    return l10n.timeJustNow;
  }
  if (diff.inMinutes < 60) {
    return l10n.timeMinutesAgo(diff.inMinutes);
  }
  if (diff.inHours < 24) {
    return l10n.timeHoursAgo(diff.inHours);
  }
  if (diff.inDays < 7) {
    return l10n.timeDaysAgo(diff.inDays);
  }
  return formatShortDate(l10n, date);
}

/// تاريخ قصير (يوم/شهر/سنة) بحسب لغة التطبيق.
String formatShortDate(AppLocalizations l10n, DateTime date) {
  final String localeName = l10n.isArabic ? 'ar' : 'en';
  try {
    return DateFormat.yMMMd(localeName).format(date);
  } catch (_) {
    // بعض بيئات التشغيل لا تحمّل بيانات intl لكل اللغات؛ نرجع لصيغة آمنة.
    return DateFormat('yyyy-MM-dd').format(date);
  }
}
