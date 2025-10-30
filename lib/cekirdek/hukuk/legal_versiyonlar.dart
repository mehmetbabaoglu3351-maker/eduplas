// lib/cekirdek/hukuk/legal_versiyonlar.dart
import 'package:flutter/foundation.dart';

@immutable
class LegalDocSpec {
  /// Mantıksal id: 'sozlesme' | 'riza' | 'aydinlatma' | 'gizlilik'
  final String id;

  /// UI'da gösterilecek başlık
  final String baslik;

  /// assets/hukuk/<locale>/*.txt  (bizim varsayılan locale = tr)
  final String assetYolu;

  /// Versiyon anahtarı (eski kodların referans verdiği)
  final String versiyonKey;

  /// Gerçek versiyon değeri (örn. '1.0.0')
  final String versiyonDegeri;

  /// Bu hukuki dokümanın uygulama içindeki route'u
  /// Örn: /hukuk/uyelik, /hukuk/acik-riza ...
  final String route;

  /// Kayıt akışında zorunlu mu?
  final bool zorunlu;

  const LegalDocSpec({
    required this.id,
    required this.baslik,
    required this.assetYolu,
    required this.versiyonKey,
    required this.versiyonDegeri,
    required this.route,
    this.zorunlu = true,
  });
}

/// EduPlas Master Senaryo v1.1 — Çekirdek hukuk versiyonları
class LegalVersiyonlar {
  // Senaryo v1.1 — versiyon etiketleri
  static const String vSozlesme = '1.0.0';
  static const String vRiza = '1.0.0';
  static const String vAyd = '1.0.0';
  static const String vGiz = '1.0.0';

  // Varsayılan (TR) asset yolları
  static const String aSozlesme = 'assets/hukuk/tr/sozlesme.txt';
  static const String aRiza = 'assets/hukuk/tr/acik_riza.txt';
  static const String aAyd = 'assets/hukuk/tr/aydinlatma.txt';
  static const String aGiz = 'assets/hukuk/tr/gizlilik.txt';

  /// Eski kodların kullandığı isim: dokumanlar
  /// Yeni kodlar da bunu kullanacak.
  static const List<LegalDocSpec> dokumanlar = [
    LegalDocSpec(
      id: 'sozlesme',
      baslik: 'Üyelik Sözleşmesi',
      assetYolu: aSozlesme,
      versiyonKey: '_vSozlesme',
      versiyonDegeri: vSozlesme,
      route: '/hukuk/uyelik',
      zorunlu: true,
    ),
    LegalDocSpec(
      id: 'riza',
      baslik: 'Açık Rıza Beyanı',
      assetYolu: aRiza,
      versiyonKey: '_vRiza',
      versiyonDegeri: vRiza,
      route: '/hukuk/acik-riza',
      zorunlu: true,
    ),
    LegalDocSpec(
      id: 'aydinlatma',
      baslik: 'Aydınlatma Metni',
      assetYolu: aAyd,
      versiyonKey: '_vAyd',
      versiyonDegeri: vAyd,
      route: '/hukuk/aydinlatma',
      zorunlu: true,
    ),
    LegalDocSpec(
      id: 'gizlilik',
      baslik: 'Gizlilik Politikası',
      assetYolu: aGiz,
      versiyonKey: '_vGiz',
      versiyonDegeri: vGiz,
      route: '/hukuk/gizlilik',
      zorunlu: true,
    ),
  ];

  /// id ile bul
  static LegalDocSpec? belgeBul(String id) {
    try {
      return dokumanlar.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  /// route ile bulmak istersen
  static LegalDocSpec? routeIleBul(String route) {
    try {
      return dokumanlar.firstWhere((e) => e.route == route);
    } catch (_) {
      return null;
    }
  }
}
