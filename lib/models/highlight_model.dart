import 'package:hive/hive.dart';

/// نموذج الاقتباس/التظليل.
///
/// ملاحظة تصميمية مهمة: هذا السجل هو "مصدر الحقيقة" للبيانات النصية
/// (النص، الملاحظة، اللون، التاريخ)، أما ملف PDF فيحمل "الرسم" فقط
/// (Highlight Annotation) حتى يظهر التظليل داخل الصفحة بعد إعادة الفتح.
class HighlightModel {
  HighlightModel({
    required this.id,
    required this.bookId,
    required this.text,
    required this.pageNumber,
    required this.colorIndex,
    required this.createdAt,
    this.bookTitle = '',
    this.note,
  });

  final String id;
  final String bookId;

  /// اسم الكتاب وقت التظليل: يُخزَّن مع الاقتباس حتى تبقى الاقتباسات
  /// قابلة للعرض والمشاركة حتى لو حُذف الكتاب من المكتبة.
  final String bookTitle;

  final String text;
  final int pageNumber;

  /// 0=أصفر، 1=أخضر، 2=أزرق، 3=أحمر (انظر AppColors.highlightColors).
  final int colorIndex;

  final String? note;
  final DateTime createdAt;

  bool get hasNote => note != null && note!.trim().isNotEmpty;

  HighlightModel copyWith({
    String? text,
    int? pageNumber,
    int? colorIndex,
    String? note,
    bool clearNote = false,
  }) {
    return HighlightModel(
      id: id,
      bookId: bookId,
      bookTitle: bookTitle,
      text: text ?? this.text,
      pageNumber: pageNumber ?? this.pageNumber,
      colorIndex: colorIndex ?? this.colorIndex,
      note: clearNote ? null : (note ?? this.note),
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'bookId': bookId,
      'bookTitle': bookTitle,
      'text': text,
      'pageNumber': pageNumber,
      'colorIndex': colorIndex,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory HighlightModel.fromMap(Map<String, dynamic> map) {
    return HighlightModel(
      id: map['id'] as String? ?? '',
      bookId: map['bookId'] as String? ?? '',
      bookTitle: map['bookTitle'] as String? ?? '',
      text: map['text'] as String? ?? '',
      pageNumber: (map['pageNumber'] as num?)?.toInt() ?? 1,
      colorIndex: (map['colorIndex'] as num?)?.toInt() ?? 0,
      note: map['note'] as String?,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

/// محوّل Hive مكتوب يدوياً.
class HighlightModelAdapter extends TypeAdapter<HighlightModel> {
  @override
  int get typeId => 1;

  @override
  HighlightModel read(BinaryReader reader) {
    final Map<dynamic, dynamic> raw = reader.readMap();
    return HighlightModel.fromMap(
      raw.map((dynamic key, dynamic value) => MapEntry<String, dynamic>(key.toString(), value)),
    );
  }

  @override
  void write(BinaryWriter writer, HighlightModel obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.toMap());
  }
}
