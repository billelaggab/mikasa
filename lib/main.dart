import 'package:flutter/material.dart';
// import 'package:syncfusion_flutter_core/core.dart'; // مطلوب فقط إذا أردت تسجيل مفتاح ترخيص
import 'package:mikasa/app.dart';
import 'package:mikasa/core/constants/app_colors.dart';
import 'package:mikasa/providers/highlights_provider.dart';
import 'package:mikasa/providers/library_provider.dart';
import 'package:mikasa/providers/settings_provider.dart';
import 'package:mikasa/router/app_router.dart';
import 'package:mikasa/services/database_service.dart';
import 'package:mikasa/services/file_service.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // إن استخدمت Syncfusion تحت ترخيص تجاري أو Community، سجّل المفتاح هنا:
  // SyncfusionLicense.registerLicense('YOUR_LICENSE_KEY');

  final DatabaseService database = DatabaseService();
  final FileService fileService = FileService();

  try {
    await database.init();
  } catch (error) {
    // فشل تهيئة قاعدة البيانات عطل جذري: نعرض شاشة واضحة بدل شاشة بيضاء.
    runApp(_BootstrapErrorApp(message: error.toString()));
    return;
  }

  final SettingsProvider settings = SettingsProvider(database)..load();

  runApp(
    MultiProvider(
      providers: [
        Provider<DatabaseService>.value(value: database),
        Provider<FileService>.value(value: fileService),
        ChangeNotifierProvider<SettingsProvider>.value(value: settings),
        ChangeNotifierProvider<LibraryProvider>(
          create: (_) => LibraryProvider(
            database: database,
            fileService: fileService,
          )..loadBooks(),
        ),
        ChangeNotifierProvider<HighlightsProvider>(
          create: (_) => HighlightsProvider(database: database)..load(),
        ),
      ],
      child: MikasaApp(router: createRouter()),
    ),
  );
}

/// شاشة احتياطية عند فشل التهيئة الأولية (نادرة: قرص ممتلئ، صلاحيات...).
class _BootstrapErrorApp extends StatelessWidget {
  const _BootstrapErrorApp({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
      ),
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Icon(Icons.error_outline_rounded, size: 56),
                const SizedBox(height: 16),
                const Text(
                  'تعذّر تشغيل التطبيق',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(message, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
