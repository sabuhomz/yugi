import 'package:flutter/material.dart';

import '../theme/duel_theme.dart';

Future<String?> promptText(
  BuildContext context, {
  required String title,
  String initial = '',
  String hint = '',
  String okLabel = 'ตกลง',
  int maxLength = 30,
}) {
  final ctrl = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: DL.panel,
      shape: duelShape(cut: 14),
      title: Text(title),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        maxLength: maxLength,
        decoration: InputDecoration(
          hintText: hint,
          enabledBorder:
              const UnderlineInputBorder(borderSide: BorderSide(color: DL.edge)),
          focusedBorder:
              const UnderlineInputBorder(borderSide: BorderSide(color: DL.cyan)),
        ),
        onSubmitted: (v) => Navigator.pop(ctx, v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('ยกเลิก', style: TextStyle(color: DL.muted)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, ctrl.text),
          child: Text(okLabel, style: const TextStyle(color: DL.cyan)),
        ),
      ],
    ),
  );
}

Future<bool> confirm(
  BuildContext context, {
  required String title,
  required String message,
  String okLabel = 'ยืนยัน',
}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: DL.panel,
      shape: duelShape(cut: 14),
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('ยกเลิก', style: TextStyle(color: DL.muted)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(okLabel, style: const TextStyle(color: DL.red)),
        ),
      ],
    ),
  );
  return r ?? false;
}
