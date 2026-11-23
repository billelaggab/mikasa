import 'dart:math';

/// توليد معرّفات فريدة محلياً دون مكتبات إضافية.
class IdUtils {
  const IdUtils._();

  static final Random _random = Random.secure();

  /// معرّف يعتمد على الزمن (ميكروثانية) + جزء عشوائي،
  /// فريد بما يكفي لسجلات محلية على جهاز واحد.
  static String newId() {
    final int timePart = DateTime.now().microsecondsSinceEpoch;
    final int randomPart = _random.nextInt(1 << 32);
    return '${timePart.toRadixString(36)}-${randomPart.toRadixString(36)}';
  }
}
