// lib/cekirdek/hukuk/hukuk_servisi.dart
import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;

/// Desteklenen hukuk türleri
enum HukukTipi {
  sozlesme,
  gizlilik,
  aydinlatma,
  acikRiza,
}

/// Basit hukuk servisi:
/// - TR ve EN için ayrı asset yolları var
/// - Dosya yoksa kısa fallback döner
class HukukServisi {
  HukukServisi._internal();
  static final HukukServisi instance = HukukServisi._internal();

  /// Dil koduna göre asset yolu üret
  String _assetPath(String dilKodu, HukukTipi tip) {
    final isTr = dilKodu.toLowerCase().startsWith('tr');

    if (isTr) {
      switch (tip) {
        case HukukTipi.sozlesme:
          return 'assets/hukuk/tr/sozlesme.txt';
        case HukukTipi.gizlilik:
          return 'assets/hukuk/tr/gizlilik.txt';
        case HukukTipi.aydinlatma:
          return 'assets/hukuk/tr/aydinlatma.txt';
        case HukukTipi.acikRiza:
          return 'assets/hukuk/tr/acik_riza.txt';
      }
    } else {
      // EN fallback
      switch (tip) {
        case HukukTipi.sozlesme:
          return 'assets/hukuk/en/contract.txt';
        case HukukTipi.gizlilik:
          return 'assets/hukuk/en/privacy.txt';
        case HukukTipi.aydinlatma:
          return 'assets/hukuk/en/disclosure.txt';
        case HukukTipi.acikRiza:
          return 'assets/hukuk/en/consent.txt';
      }
    }
  }

  /// Asset'ten oku
  Future<String> yukle(String dilKodu, HukukTipi tip) async {
    final path = _assetPath(dilKodu, tip);
    try {
      final data = await rootBundle.loadString(path);
      return data;
    } catch (_) {
      // Fallback
      return 'Bu hukuk metni şu anda gösterilemiyor ($path). Lütfen daha sonra tekrar deneyin.';
    }
  }

  /// TR için kısa toplu yükleme
  Future<Map<HukukTipi, String>> hepsiniYukle(String dilKodu) async {
    final Map<HukukTipi, String> sonuc = {};
    for (final tip in HukukTipi.values) {
      sonuc[tip] = await yukle(dilKodu, tip);
    }
    return sonuc;
  }
}
