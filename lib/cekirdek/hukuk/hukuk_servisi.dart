// lib/cekirdek/hukuk/hukuk_servisi.dart
import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;
import 'package:eduplas/cekirdek/dil/dil_yoneticisi.dart';

class HukukServisi {
  HukukServisi._internal();
  static final HukukServisi _i = HukukServisi._internal();
  factory HukukServisi() => _i;

  /// [belgeId]: 'sozlesme' | 'acik_riza' | 'aydinlatma' | 'gizlilik'
  /// [locale]: verilmezse sistem dilini kullanır
  Future<String> yukle(String belgeId, {String? locale}) async {
    final normalizedLocale =
        _normalizeLocale(locale ?? DilYoneticisi.instance.aktifDil);
    final pathPrimary = 'assets/hukuk/$normalizedLocale/$belgeId.txt';
    final pathFallback = 'assets/hukuk/tr/$belgeId.txt';

    try {
      final data = await rootBundle.loadString(pathPrimary, cache: true);
      return _ekleResmiUyari(data, locale: normalizedLocale);
    } catch (_) {
      try {
        final dataTr = await rootBundle.loadString(pathFallback, cache: true);
        return _ekleResmiUyari(
          dataTr,
          locale: normalizedLocale,
          fallback: true,
        );
      } catch (e) {
        return '⚠️ ${belgeId.toUpperCase()} metni yüklenemedi.\n'
            'Lütfen sistem yöneticisine bildirin.\n\nHata: $e';
      }
    }
  }

  // ignore: unused_element
  Future<String> _aiCeviri(String text, String targetLang) async {
    // ileride AI çeviri buraya
    return text;
  }

  String _ekleResmiUyari(
    String text, {
    required String locale,
    bool fallback = false,
  }) {
    const resmiUyari = '''

---
Not: Bu metin, EduPlas'ın resmi Türkçe sürümünün tercümesidir.
Ana dilinizde sürüm bulunmuyorsa, Türkçe sürüm yasal geçerliliğe sahiptir.
© 2025 EduPlas
''';

    if (locale == 'tr' || text.contains('EduPlas\'ın resmi Türkçe')) {
      return text;
    }
    if (fallback) {
      return text + resmiUyari;
    }
    return text;
  }

  String _normalizeLocale(String raw) {
    final lower = raw.toLowerCase();
    if (lower.startsWith('tr')) return 'tr';
    if (lower.startsWith('en')) return 'en';
    if (lower.startsWith('es')) return 'es';
    if (lower.startsWith('fr')) return 'fr';
    if (lower.startsWith('de')) return 'de';
    if (lower.startsWith('ar')) return 'ar';
    return 'tr';
  }
}
