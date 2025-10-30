// lib/cekirdek/arayuz/app_logo.dart
import 'package:flutter/material.dart';

/// Sayfa yapısına göre akıllı boyutlanan logo.
/// - Varsayılan: adaptif (ekran genişliği, textScale, klavye, yoğunluk).
/// - İstersen sabit boy verebilirsin: [size] parametresi.
class AppLogo extends StatelessWidget {
  final double? size;          // sabit boy istersen
  final bool daire;            // daire kesim
  final bool compactHint;      // form yoğun sayfalarda küçült
  final EdgeInsetsGeometry? padding;

  const AppLogo({
    super.key,
    this.size,
    this.daire = false,
    this.compactHint = false,
    this.padding,
  });

  double _suggestedSize(BuildContext context) {
    final mq = MediaQuery.of(context);
    final width = mq.size.width;
    final shortest = mq.size.shortestSide;
    final textScale = mq.textScaler.scale(1.0);
    final keyboardOpen = mq.viewInsets.bottom > 0.0;

    double base;
    if (width >= 1000 || shortest >= 600) {
      base = 140; // geniş ekran
    } else if (width >= 700) {
      base = 110;
    } else {
      base = 84;  // telefon
    }

    if (keyboardOpen) base *= 0.9;    // klavye açıksa küçült
    if (textScale > 1.2) base *= 0.9; // büyük yazı ölçeğinde küçült
    if (compactHint) base *= 0.9;     // form yoğunluğu

    return base.clamp(56.0, 180.0);
  }

  @override
  Widget build(BuildContext context) {
    final resolved = size ?? _suggestedSize(context);
    final borderRadius =
        daire ? BorderRadius.circular(resolved / 2) : BorderRadius.circular(16);

    return Padding(
      padding: padding ?? const EdgeInsets.only(top: 8, bottom: 6),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Image.asset(
          'assets/images/eduplas_logo.png',
          width: resolved,
          height: resolved,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(
            Icons.school,
            size: resolved * 0.8,
            color: Colors.grey.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}


