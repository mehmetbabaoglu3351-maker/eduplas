// Sayfanın üstünde yumuşak bir uyarı bandı (3.18+ ile uyumlu sürüm)
import 'package:flutter/material.dart';

class ErrorBanner extends StatelessWidget {
  final String? message;
  final VoidCallback? onClose;

  const ErrorBanner({super.key, this.message, this.onClose});

  @override
  Widget build(BuildContext context) {
    if (message == null || message!.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        // 3.18+ : withOpacity → withValues(alpha: …)
        color: scheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.error.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message!,
              style: const TextStyle(fontSize: 13.5),
            ),
          ),
          if (onClose != null)
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: onClose,
              splashRadius: 18,
              tooltip: 'Kapat',
            ),
        ],
      ),
    );
  }
}


