# 📚 Mikasa — قارئ PDF للقراءة الفعّالة

تطبيق أندرويد (Flutter) يركّز على **القراءة الفعّالة**: تظليل النصوص المهمة داخل الكتب، حفظها
كاقتباسات مع ملاحظات، والعودة إليها بضغطة واحدة — حتى بعد إغلاق التطبيق.
**يعمل دون اتصال بالإنترنت بالكامل**، وكل البيانات تبقى على الجهاز (Hive + ملفات PDF محلية).

> حالة المشروع: مكتمل وظيفياً ومُتحقَّق منه بـ `flutter analyze` (بلا أي ملاحظة) و`flutter test`
> (14 اختباراً ناجحاً). البناء النهائي APK يحتاج Android SDK على جهازك (انظر «التشغيل»).

---

## ✨ الميزات المنفَّذة

| المجال | التفاصيل |
|---|---|
| **المكتبة** | استيراد PDF عبر `file_picker`، ترتيب حسب آخر فتح، عرض (الاسم، آخر صفحة، عدد الاقتباسات، آخر وقت فتح، شريط تقدم)، حذف مع خيار «حذف الكتاب فقط» أو «حذف الكتاب والاقتباسات» |
| **القارئ** | Syncfusion PDF Viewer بتمرير عمودي مستمر، تكبير/تصغير (إصبعين + أزرار)، شريط تنقل (Slider + إدخال رقم صفحة + السابق/التالي)، حفظ آخر صفحة تلقائياً وفتحها عند العودة، وضع ليلي يعكس ألوان الصفحات |
| **⭐ التظليل** | تحديد أي نص ← قائمة سياق مخصّصة (٤ ألوان + نسخ + ملاحظة) ← يُحفظ اقتباس في Hive **ويُرسم التظليل فعلياً داخل ملف PDF** (Highlight Annotation) ويظهر بعد إعادة الفتح |
| **الاقتباسات** | شاشة لكل كتاب + شاشة «كل الاقتباسات»، فلترة باللون، بحث في النصوص والملاحظات، انتقال إلى صفحة الاقتباس عبر `PdfViewerController.jumpToPage`، تعديل/مسح الملاحظة، مشاركة كنص (`share_plus`)، حذف |
| **الواجهة** | Material 3، عربي RTL + إنجليزي (تبديل فوري)، وضع ليلي/نهاري/حسب النظام، انتقالات ناعمة، Hero Animation لغلاف الكتاب، حالات فارغة مع CTA |
| **الصلابة** | معالجة أخطاء واضحة (ملف تالف، صلاحية مرفوضة، ملف محذوف)، كتابة ذرّية لملف PDF، عدم تكرار الكتاب عند إعادة الاستيراد |

---

## 🚀 التشغيل

### المتطلبات
- Flutter **3.35+** (تم التحقق على 3.50.1 / Dart 3.14) و Android SDK (API 23+).
- جهاز/محاكي أندرويد.

### الخطوات
```bash
cd mikasa
flutter pub get
flutter analyze        # اختياري: يجب أن تكون النتيجة "No issues found!"
flutter test           # اختياري: 14 اختباراً
flutter run            # على جهاز/محاكي متصل
flutter build apk --release
```

> **ترخيص Syncfusion:** حزم PDF من Syncfusion تظهر شعار ترخيص إذا لم يُسجَّل مفتاح.
> سجّل مجاناً في [Community License](https://www.syncfusion.com/products/communitylicense)
> ثم أزل التعليق عن السطر في `lib/main.dart`:
> ```dart
> SyncfusionLicense.registerLicense('YOUR_LICENSE_KEY');
> ```

> ملاحظة: مجلد `android/` مُولَّد وجاهز (minSdk = 23، الاسم = Mikasa، الصلاحيات مضبوطة).
> إن أعدت توليده بـ `flutter create .` فاستبدل الملفين
> `android/app/src/main/AndroidManifest.xml` و`android/app/build.gradle.kts` بالنسختين هنا.

### ⚠️ مهم جداً

عند توليد ملفات مشروع فلاتر عبر أمر `flutter create` يتم إنشاء ملف `test/widget_test.dart` وهو ملف اختبار حقيقي لا علاقة له بملفات التطبيق.

قم بحذف ملف `test/widget_test.dart` عبر الأمر التالي من داخل مجلد المشروع:

**(إذا كنت تستخدم ويندوز)**

```powershell
Remove-Item .\test\widget_test.dart
```

**(إذا كنت تستخدم ماك أو لينكس)**

```bash
rm test/widget_test.dart
```

الإبقاء على هذا الملف عديم الصلة ينتج أخطاء تمنع بناء التطبيق.

---

## 🗂️ بنية المشروع (ملفاً بملف)

```
lib/
├── main.dart                       تهيئة Hive + حقن الـ Providers + تشغيل التطبيق
├── app.dart                        MaterialApp.router: الثيم، اللغة، اتجاه RTL/LTR
├── core/
│   ├── constants/
│   │   ├── app_colors.dart         الهوية اللونية + ألوان التظليل الأربعة (مرتبطة بـ colorIndex)
│   │   └── app_strings.dart        كل نصوص التطبيق عربي/إنجليزي (بدون codegen)
│   ├── theme/app_theme.dart        ThemeData نهاري/ليلي (Material 3)
│   └── utils/
│       ├── app_failure.dart        أكواد الأعطال (invalidPdf, permissionDenied, fileMissing…)
│       ├── id_utils.dart           توليد معرّفات فريدة للاقتباسات
│       ├── snackbars.dart          رسائل موحّدة (خطأ/معلومة) مترجمة
│       └── time_utils.dart         "قبل 5 دقائق" وتواريخ قصيرة
├── models/
│   ├── book_model.dart             BookModel + محوّل Hive يدوي (typeId 0)
│   └── highlight_model.dart        HighlightModel + محوّل Hive يدوي (typeId 1)
├── services/
│   ├── database_service.dart       كل عمليات Hive (كتب/اقتباسات/حذف مؤجَّل/إعدادات)
│   └── file_service.dart           الاستيراد، بصمة الملف، الكتابة الذرّية، الحذف
├── providers/
│   ├── library_provider.dart       حالة المكتبة (استيراد/حذف/تقدم القراءة)
│   ├── highlights_provider.dart    حالة الاقتباسات (إضافة/تعديل/حذف/فلترة/بحث)
│   └── settings_provider.dart      المظهر، اللغة، وضع القراءة الليلي (محفوظة في Hive)
├── router/app_router.dart          go_router: /  ·  /highlights  ·  /reader/:bookId  ·  /reader/:bookId/highlights
├── screens/
│   ├── library_screen.dart         المكتبة (شبكة بطاقات + استيراد + حذف)
│   ├── pdf_reader_screen.dart      القارئ + منطق التظليل (أهم ملف في المشروع)
│   └── highlights_screen.dart      الاقتباسات + الفلترة + البحث + المشاركة
└── widgets/
    ├── book_card.dart              بطاقة كتاب + Hero + شريط تقدم
    ├── highlight_tile.dart         بطاقة اقتباس (شريط لوني، صفحة، ملاحظة، قائمة إجراءات)
    ├── color_picker_menu.dart      قائمة السياق: ٤ ألوان + نسخ + ملاحظة
    ├── page_navigator_bar.dart     Slider + إدخال رقم الصفحة + سابق/تالي
    ├── note_editor_sheet.dart      لوحة كتابة/تعديل الملاحظة
    ├── settings_sheet.dart         لوحة الإعدادات
    └── empty_state.dart            الحالات الفارغة مع زر دعوة لاتخاذ إجراء
```

---

## ⚠️ كيف يعمل التظليل (أهم جزء تقني)

1. **التقاط النص:** `SfPdfViewer.onTextSelectionChanged` يعطي `selectedText`
   و`globalSelectedRegion` (موضع التحديد على الشاشة).
2. **قائمة سياق مخصّصة:** نضع `canShowTextSelectionMenu: false` ثم نعرض
   `ColorPickerMenu` داخل `OverlayEntry` فوق النص، مع ضمان بقائها داخل حدود الشاشة.
3. **إحداثيات دقيقة للرسم:** لا نستخدم موضع الشاشة للرسم، بل
   `SfPdfViewerState.getSelectedTextLines()` التي تعيد `List<PdfTextLine>`
   (نص كل سطر + `Rect` بإحداثيات الصفحة + رقم الصفحة). لذلك يظهر التظليل
   **بالضبط فوق النص** بصرف النظر عن التكبير أو الوضع الليلي.
4. **حفظ مزدوج ومترابط:**
   - `HighlightModel` في Hive = مصدر الحقيقة (النص، الصفحة، اللون، الملاحظة، التاريخ)
     وهو ما تعرضه شاشة الاقتباسات (بحث/فلترة/مشاركة/تعديل ملاحظة).
   - `HighlightAnnotation(textBoundsCollection: lines)` يُضاف عبر
     `PdfViewerController.addAnnotation` = الرسم داخل الصفحة.
   - نضع **معرّف الاقتباس في `annotation.name`** ليكون جسراً بين السجل والرسم.
5. **التثبيت في الملف:** `PdfViewerController.saveDocument()` يعيد بايتات PDF
   (مع التظليلات)، و`FileService.writePdfBytes` يكتبها **ذرّياً**
   (ملف `.tmp` ثم استبدال) حتى لا يتلف الكتاب إذا انقطع التطبيق.
   لذا التظليل يظهر حتى بعد إغلاق التطبيق أو إعادة تشغيل الهاتف.
6. **الحذف من شاشة الاقتباسات:** لا يوجد عارض مفتوح لمسح الرسم، لذلك يُسجَّل
   المعرّف في صندوق `pending_removals`؛ وعند أول فتح للكتاب يقرأ القارئ
   `getAnnotations()` ويحذف ما يطابق ثم يعيد الحفظ (بدون تدخّل من المستخدم).

### نموذج البيانات
```dart
BookModel      { id, title, filePath, lastPage, totalPages, lastOpened, addedAt }
HighlightModel { id, bookId, bookTitle, text, pageNumber, colorIndex, note, createdAt }
```
- `id` للكتاب = **بصمة محتوى** (sha256 لأول 64KB + حجم الملف) ← ثابتة حتى لو تغيّر اسم الملف،
  ولا تُنشئ نسخة مكررة عند إعادة استيراد نفس الكتاب.
- `colorIndex`: 0=أصفر، 1=أخضر، 2=أزرق، 3=أحمر.
- صناديق Hive: `books` · `highlights` · `pending_removals` · `settings`.

---

## 🔐 الصلاحيات
```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
                 android:maxSdkVersion="32" />
```
- **لِماذا لا نطلب `MANAGE_EXTERNAL_STORAGE`؟** `file_picker` يستخدم Storage Access
  Framework الذي لا يحتاج صلاحيات تخزين على أندرويد 13+، و`MANAGE_EXTERNAL_STORAGE`
  تفرض Google Play تبريراً لاستخدامها. السطر موجود **معلَّقاً** في
  `AndroidManifest.xml` إن أردت تفعيله لاحقاً.
- التطبيق ينسخ الملف المختار إلى مساحته الخاصة (`<documents>/books/<id>.pdf`) لأن
  تعديل الـ PDF (كتابة التظليلات) يحتاج ملكية الملف.

---

## 🧪 الاختبارات
| الملف | المحتوى |
|---|---|
| `test/models_test.dart` | نماذج البيانات، `progress`، مسح الملاحظة، ألوان التظليل، نصوص ar/en |
| `test/app_flow_test.dart` | Hive (CRUD، الترتيب، الفلترة، الحذف المؤجَّل، الإعدادات) + اختبار واجهة لشاشة المكتبة |

```bash
flutter analyze   # No issues found!
flutter test      # All tests passed! (14)
```
> لم يُختبر بناء APK داخل بيئة إعداد هذا الكود لأنها لا تحتوي Android SDK؛
> الكود مُتحقَّق منه بالمحلّل والاختبارات، وشاشة القارئ تحتاج جهازاً حقيقياً
> لاختبار أداء التمرير والرسم.

---

## ⚡ الأداء مع ملفات كبيرة (+500 صفحة)
- `pageLayoutMode: continuous` مع `scrollDirection: vertical` → الصفحات تُرسم عند الحاجة فقط.
- لا يوجد أي معالجة لكل الصفحات مسبقاً (لا استخراج نصوص كامل) — فقط الأسطر المحددة وقت التظليل.
- كشف التمرير (`onPageChanged`) يكتب في Hive بعد **تأخير 700ms** لتقليل عمليات القرص.
- شاشة الاقتباسات تقرأ من الذاكرة (Provider) وتُفلتر محلياً بدون استعلامات متكررة.
- `saveDocument` يُنفَّذ فقط عند إضافة/حذف تظليل، وليس أثناء القراءة.

---

## 🧭 قرارات معمارية سريعة
- **Hive بـ Adapters يدوية** بدل `build_runner`: لا خطوات توليد كود، وترقية النموذج سهلة
  (خرائط + قيم افتراضية آمنة).
- **Provider** بدل Riverpod: أبسط لفريق صغير ويلبي الحاجة دون طبقات زائدة.
- **الخدمات لا تعرف الواجهة**: `DatabaseService`/`FileService` تعيد نتائج أو ترمي
  `AppFailure(code)` وتتولّى الواجهة الترجمة → قابلية اختبار وتوسّع أعلى (SOLID).
- **`File(book.filePath)`** يُمرَّر لـ `SfPdfViewer.file` (توقيع الحزمة الحالية)، ووضع
  الليلي يُنفَّذ بـ `ColorFiltered` بمصفوفة ثابتة حتى **لا يُعاد تحميل المستند**
  ويبقى المستخدم في نفس الصفحة.

## 🔭 خارج النطاق الحالي (جاهز للتوسّع)
تصدير الاقتباسات إلى PDF/Markdown · مزامنة سحابية اختيارية · قراءة صوتية TTS للاقتباسات ·
إحصائيات القراءة اليومية · دعم EPUB · وسوم (Tags) وفهرس بحث داخل الكتاب.
