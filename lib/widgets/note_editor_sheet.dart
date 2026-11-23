import 'package:flutter/material.dart';
import 'package:mikasa/core/constants/app_strings.dart';

/// يفتح لوحة كتابة/تعديل الملاحظة.
///
/// القيمة المُعادة:
/// - `null`  → ألغى المستخدم (لا تغيير).
/// - `''`    → طلب مسح الملاحظة.
/// - أي نص  → الملاحظة الجديدة.
Future<String?> showNoteEditorSheet(
  BuildContext context, {
  String? initialNote,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (BuildContext context) => _NoteEditorSheet(initialNote: initialNote),
  );
}

class _NoteEditorSheet extends StatefulWidget {
  const _NoteEditorSheet({this.initialNote});

  final String? initialNote;

  @override
  State<_NoteEditorSheet> createState() => _NoteEditorSheetState();
}

class _NoteEditorSheetState extends State<_NoteEditorSheet> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialNote ?? '');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool hasContent = _controller.text.trim().isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 4,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            l10n.noteSheetTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            autofocus: true,
            minLines: 3,
            maxLines: 6,
            textInputAction: TextInputAction.newline,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(hintText: l10n.noteSheetHint),
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              if (hasContent)
                TextButton(
                  onPressed: () => Navigator.of(context).pop(''),
                  child: Text(l10n.actionClear),
                ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.actionCancel),
              ),
              const SizedBox(width: 6),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
                child: Text(l10n.actionSave),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
