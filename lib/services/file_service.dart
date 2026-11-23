import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:mikasa/core/utils/app_failure.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// نتيجة استيراد ملف PDF.
class ImportedPdf {
  const ImportedPdf({
    required this.id,
    required this.title,
    required this.filePath,
    required this.totalPages,
    required this.sizeBytes,
  });

  /// بصمة محتوى الملف (sha256 للجزء الأول + الحجم) — ثابتة حتى لو تغيّر الاسم.
  final String id;
  final String title;
  final String filePath;
  final int totalPages;
  final int sizeBytes;
}

/// كل ما يتعلّق بالملفات: الاستيراد، النسخ داخل مجلد التطبيق، الكتابة الآمنة، الحذف.
///
/// مبدأ مهم: لا نفتح ملف المستخدم الأصلي مباشرة، بل ننسخه إلى مجلد التطبيق،
/// لأن كتابة التظليلات تحتاج صلاحية تعديل الملف (وملفات SAF لا تسمح بذلك دائماً).
class FileService {
  static const String _booksFolderName = 'books';
  static const int _idSampleSize = 64 * 1024;

  Directory? _cachedBooksDirectory;

  /// مجلد الكتب داخل مساحة التطبيق الخاصة.
  Future<Directory> booksDirectory() async {
    final Directory? cached = _cachedBooksDirectory;
    if (cached != null && await cached.exists()) {
      return cached;
    }
    final Directory documents = await getApplicationDocumentsDirectory();
    final Directory booksDir = Directory(p.join(documents.path, _booksFolderName));
    if (!await booksDir.exists()) {
      await booksDir.create(recursive: true);
    }
    _cachedBooksDirectory = booksDir;
    return booksDir;
  }

  /// يفتح منتقي الملفات ويستورد ملف PDF.
  ///
  /// يعيد `null` إذا ألغى المستخدم الاختيار، ويرمي [AppFailure] عند أي عطل
  /// حتى تتمكن الواجهة من عرض رسالة مفهومة.
  Future<ImportedPdf?> importPdf() async {
    final PlatformFile? picked;
    try {
      picked = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: <String>['pdf'],
        dialogTitle: 'PDF',
      );
    } on PlatformException catch (error) {
      throw AppFailure(FailureCode.permissionDenied, details: error);
    } catch (error) {
      throw AppFailure(FailureCode.unknown, details: error);
    }

    if (picked == null) {
      return null;
    }

    final Uint8List bytes;
    try {
      bytes = await picked.readAsBytes();
    } on PlatformException catch (error) {
      throw AppFailure(FailureCode.permissionDenied, details: error);
    } catch (error) {
      throw AppFailure(FailureCode.unknown, details: error);
    }

    return storePdf(bytes, picked.name);
  }

  /// يتحقق من الملف، يحسب عدد صفحاته وبصمته، ثم ينسخه إلى مجلد التطبيق.
  Future<ImportedPdf> storePdf(Uint8List bytes, String originalName) async {
    if (!_looksLikePdf(bytes)) {
      throw const AppFailure(FailureCode.invalidPdf);
    }

    final int totalPages = _countPages(bytes);
    final String id = _buildId(bytes);
    final Directory directory = await booksDirectory();
    final File file = File(p.join(directory.path, '$id.pdf'));

    try {
      await file.writeAsBytes(bytes, flush: true);
    } on FileSystemException catch (error) {
      throw AppFailure(FailureCode.unknown, details: error);
    }

    return ImportedPdf(
      id: id,
      title: _cleanTitle(originalName),
      filePath: file.path,
      totalPages: totalPages,
      sizeBytes: bytes.length,
    );
  }

  /// كتابة بايتات PDF (بعد إضافة/حذف التظليلات) بشكل آمن:
  /// نكتب في ملف مؤقت أولاً ثم نستبدل الأصل، حتى لا يتلف الملف إذا توقف التطبيق.
  Future<void> writePdfBytes(String targetPath, List<int> bytes) async {
    final File temp = File('$targetPath.tmp');
    await temp.writeAsBytes(bytes, flush: true);
    try {
      await temp.rename(targetPath);
    } on FileSystemException {
      // على بعض الأنظمة لا يمكن الاستبدال المباشر، نحذف ثم نعيد التسمية.
      final File target = File(targetPath);
      if (await target.exists()) {
        await target.delete();
      }
      await temp.rename(targetPath);
    }
  }

  Future<bool> exists(String path) => File(path).exists();

  Future<void> deleteBookFile(String path) async {
    try {
      final File file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } on FileSystemException {
      // لا نُفشل عملية الحذف بسبب ملف مقفل: الكتاب أُزيل من المكتبة على أي حال.
    }
  }

  // --------------------------------------------------------------- داخلي

  bool _looksLikePdf(Uint8List bytes) {
    if (bytes.length < 5) {
      return false;
    }
    const List<int> header = <int>[0x25, 0x50, 0x44, 0x46]; // "%PDF"
    for (int i = 0; i < header.length; i++) {
      if (bytes[i] != header[i]) {
        return false;
      }
    }
    return true;
  }

  int _countPages(Uint8List bytes) {
    PdfDocument? document;
    try {
      document = PdfDocument(inputBytes: bytes);
      return document.pages.count;
    } catch (error) {
      throw AppFailure(FailureCode.invalidPdf, details: error);
    } finally {
      document?.dispose();
    }
  }

  /// بصمة الملف: نأخذ أول 64KB فقط (سريع حتى مع ملفات ضخمة) + الحجم الكلي.
  String _buildId(Uint8List bytes) {
    final Uint8List sample = bytes.length <= _idSampleSize
        ? bytes
        : bytes.sublist(0, _idSampleSize);
    final Digest digest = sha256.convert(<int>[
      ...sample,
      ...utf8.encode('|${bytes.length}'),
    ]);
    return digest.toString().substring(0, 24);
  }

  String _cleanTitle(String rawName) {
    final String baseName = rawName.split('/').last.split(r'\').last;
    if (baseName.toLowerCase().endsWith('.pdf')) {
      return baseName.substring(0, baseName.length - 4);
    }
    return baseName;
  }
}
