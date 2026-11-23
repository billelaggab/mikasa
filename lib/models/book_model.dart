import 'package:hive/hive.dart';

/// نموذج الكتاب (ملف PDF واحد داخل المكتبة).
///
/// لماذا لا نستخدم `title` كمعرّف؟ لأن عناوين الملفات تتكرر وتتغيّر.
/// الحقل `id` هو بصمة محتوى الملف (sha256 لبدايته + حجمه) لذا يبقى ثابتاً
/// حتى لو أُعيد استيراد الملف باسم مختلف.
class BookModel {
  BookModel({
    required this.id,
    required this.title,
    required this.filePath,
    required this.lastOpened,
    this.lastPage = 1,
    this.totalPages = 0,
    DateTime? addedAt,
  }) : addedAt = addedAt ?? lastOpened;

  final String id;
  final String title;

  /// مسار النسخة المحلية داخل مجلد التطبيق (وليس مسار الملف الأصلي).
  final String filePath;

  /// آخر صفحة وصل إليها المستخدم (1-based).
  int lastPage;

  /// إجمالي الصفحات، يُحدَّث عند أول فتح من داخل العارض.
  int totalPages;

  /// آخر مرة فُتح فيها الكتاب (تُستخدم في الترتيب وفي بطاقة المكتبة).
  DateTime lastOpened;

  final DateTime addedAt;

  /// نسبة التقدم بين 0 و 1 لحساب شريط التقدم.
  double get progress {
    if (totalPages <= 0) {
      return 0;
    }
    return (lastPage / totalPages).clamp(0.0, 1.0);
  }

  BookModel copyWith({
    String? title,
    String? filePath,
    int? lastPage,
    int? totalPages,
    DateTime? lastOpened,
  }) {
    return BookModel(
      id: id,
      title: title ?? this.title,
      filePath: filePath ?? this.filePath,
      lastPage: lastPage ?? this.lastPage,
      totalPages: totalPages ?? this.totalPages,
      lastOpened: lastOpened ?? this.lastOpened,
      addedAt: addedAt,
    );
  }

  /// تحويل إلى خريطة (تُخزَّن في Hive كـ Map، وهو أسرع وأبسط من adapters حقلاً بحقل،
  /// ويجعل ترقية النموذج مستقبلاً سهلة عبر قيم افتراضية).
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'filePath': filePath,
      'lastPage': lastPage,
      'totalPages': totalPages,
      'lastOpened': lastOpened.toIso8601String(),
      'addedAt': addedAt.toIso8601String(),
    };
  }

  factory BookModel.fromMap(Map<String, dynamic> map) {
    return BookModel(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      filePath: map['filePath'] as String? ?? '',
      lastPage: (map['lastPage'] as num?)?.toInt() ?? 1,
      totalPages: (map['totalPages'] as num?)?.toInt() ?? 0,
      lastOpened: DateTime.tryParse(map['lastOpened'] as String? ?? '') ?? DateTime.now(),
      addedAt: DateTime.tryParse(map['addedAt'] as String? ?? ''),
    );
  }
}

/// محوّل Hive مكتوب يدوياً (بدون build_runner).
class BookModelAdapter extends TypeAdapter<BookModel> {
  @override
  int get typeId => 0;

  @override
  BookModel read(BinaryReader reader) {
    final Map<dynamic, dynamic> raw = reader.readMap();
    return BookModel.fromMap(
      raw.map((dynamic key, dynamic value) => MapEntry<String, dynamic>(key.toString(), value)),
    );
  }

  @override
  void write(BinaryWriter writer, BookModel obj) {
    writer
      ..writeByte(1) // عدد الحقول (للتوسعة المستقبلية)
      ..writeByte(0)
      ..write(obj.toMap());
  }
}
