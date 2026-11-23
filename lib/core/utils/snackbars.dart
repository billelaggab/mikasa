import 'package:flutter/material.dart';
import 'package:mikasa/core/constants/app_strings.dart';
import 'package:mikasa/core/utils/app_failure.dart';

/// رسالة خطأ موحّدة: تحوّل كود العطل إلى نص مترجم.
void showFailureSnackBar(BuildContext context, FailureCode? code) {
  final AppLocalizations l10n = AppLocalizations.of(context);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(l10n.failureMessage(code ?? FailureCode.unknown)),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 4),
      ),
    );
}

/// رسالة معلومات قصيرة، مع إمكانية إضافة زر إجراء (مثل "إضافة ملاحظة").
void showInfoSnackBar(
  BuildContext context,
  String message, {
  SnackBarAction? action,
  Duration duration = const Duration(seconds: 3),
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        action: action,
        duration: duration,
      ),
    );
}
