// lib/cekirdek/arayuz/input_decorations.dart
// Material 3 uyumlu, koyu/açık temalarda okunabilir ortak InputDecoration
// Not: surfaceContainerHighest ve withValues(alpha: ...) kullanır (3.18+ uyumlu)

import 'package:flutter/material.dart';

class EduInput {
  static InputDecoration decorated(
    BuildContext context, {
    required String label,
    String? hint,
    Widget? prefix,
    Widget? suffix,
    String? helperText,
  }) {
    final scheme = Theme.of(context).colorScheme;

    // outline: %24 opaklık
    final baseOutline = scheme.outline.withValues(alpha: 0.24);

    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helperText,
      prefixIcon: prefix,
      suffixIcon: suffix,
      isDense: true,
      filled: true,
      // 3.18+: surfaceVariant yerine surfaceContainerHighest öneriliyor
      fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.18),
      border: _border(baseOutline),
      enabledBorder: _border(baseOutline),
      focusedBorder: _border(scheme.primary, 1.6),
      errorBorder: _border(scheme.error.withValues(alpha: 0.90)),
      focusedErrorBorder: _border(scheme.error.withValues(alpha: 0.90), 1.6),
      errorMaxLines: 2,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  static OutlineInputBorder _border(Color color, [double width = 1.0]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}


