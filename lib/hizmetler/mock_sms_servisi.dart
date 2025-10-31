// lib/hizmetler/mock_sms_servisi.dart
// EduPlas A1 – Güvenli Giriş ve OTP Simülasyon Servisi
//
// Bu sınıf artık yalnızca OTP (telefon doğrulama) kodu üretir ve doğrular.
// Gerçek SMS API yok; debug modunda konsola yazılır.
// Kurtarma akışı (gonderKurtarmaKodu) devre dışı bırakılmıştır.

import 'dart:math';
import 'package:flutter/foundation.dart';

class MockSmsServisi {
  MockSmsServisi._();
  static final MockSmsServisi _i = MockSmsServisi._();
  factory MockSmsServisi() => _i;

  final Map<String, String> _sonKod = {}; // telefon -> kod eşleşmesi

  /// 6 haneli rastgele kod üretir, saklar ve geri döner
  Future<String> gonderKod(String telefon) async {
    final rnd = Random();
    final code = List.generate(6, (_) => rnd.nextInt(10)).join();
    _sonKod[telefon] = code;

    if (kDebugMode) {
      // ignore: avoid_print
      print('[MOCK-OTP] $telefon için doğrulama kodu: $code');
    }
    return code;
  }

  /// Belirli telefona ait son kodu döndürür (yoksa boş)
  String sonKod(String telefon) => _sonKod[telefon] ?? '';

  /// Doğrulama işlemi (mock)
  bool dogrula(String telefon, String kod) {
    return _sonKod[telefon] != null && _sonKod[telefon] == kod.trim();
  }

  /// Kurtarma servisi devre dışı (artık kullanılmıyor)
  @Deprecated('Artık kullanılmıyor, sadece OTP için gonderKod() kullan.')
  void gonderKurtarmaKodu(String _) {}
}
