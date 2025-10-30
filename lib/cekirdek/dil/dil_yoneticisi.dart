// lib/cekirdek/dil/dil_yoneticisi.dart
import 'dart:ui';
import 'package:flutter/foundation.dart';

/// Uygulama dili için basit ve reaktif yönetici.
/// Dinleyiciler dil değişince yeniden build olabilir.
class DilYoneticisi extends ChangeNotifier {
  DilYoneticisi._();
  static final DilYoneticisi instance = DilYoneticisi._();

  String _geciciDil = '';

  /// Sistem dilini oku (cihaz dili)
  String get sistemDili {
    final locale = PlatformDispatcher.instance.locale;
    return _normalize(locale.languageCode);
  }

  /// Şu an uygulamanın kullanacağı dil
  String get aktifDil => _geciciDil.isNotEmpty ? _geciciDil : sistemDili;

  /// Giriş ekranı veya ayarlar burayı çağıracak
  void dilAyarla(String code) {
    _geciciDil = _normalize(code);
    notifyListeners(); // <<<<< ÖNEMLİ
  }

  String _normalize(String raw) {
    final l = raw.toLowerCase();
    if (l.startsWith('tr')) return 'tr';
    if (l.startsWith('en')) return 'en';
    if (l.startsWith('de')) return 'de';
    if (l.startsWith('fr')) return 'fr';
    if (l.startsWith('ar')) return 'ar';
    return 'tr';
  }
}
