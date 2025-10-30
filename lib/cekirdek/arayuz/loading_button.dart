// lib/cekirdek/arayuz/loading_button.dart
// Form geçerli değilken disable, işlem sırasında spinner gösterir.

import 'package:flutter/material.dart';

class LoadingButton extends StatelessWidget {
  final String text;
  final Future<void> Function()? onPressedAsync;
  final bool isBusy;
  final bool enabled;
  final IconData? icon;

  const LoadingButton({
    super.key,
    required this.text,
    this.onPressedAsync,
    this.isBusy = false,
    this.enabled = true,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final canTap = enabled && !isBusy && onPressedAsync != null;
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: canTap ? () async => await onPressedAsync!.call() : null,
        icon: isBusy
            ? const SizedBox(
                width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.2),
              )
            : Icon(icon ?? Icons.login),
        label: Text(text),
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}


