// lib/hizmetler/mock_sms_servisi.dart
import 'dart:math';
import 'package:flutter/foundation.dart';

class MockSmsServisi {
  MockSmsServisi._();
  static final MockSmsServisi _i = MockSmsServisi._();
  factory MockSmsServisi() => _i;

  final Map<String, String> _sonKod = {}; // telefon -> kod

  /// 6 haneli kod üretir, saklar ve geri döner
  Future<String> gonderKod(String telefon) async {
    final rnd = Random();
    final code = List.generate(6, (_) => rnd.nextInt(10)).join();
    _sonKod[telefon] = code;

    // Konsola yaz (debug'da). Ama asıl görünürlük UI'da.
    if (kDebugMode) {
      // ignore: avoid_print
      print('[MOCK-SMS] $telefon için kod: $code');
    }
    return code;
  }

  /// Son üretilen kodu döndürür; yoksa boş string
  String sonKod(String telefon) => _sonKod[telefon] ?? '';

  /// Doğrulama (mock)
  bool dogrula(String telefon, String kod) {
    return _sonKod[telefon] != null && _sonKod[telefon] == kod.trim();
  }

  void gonderKurtarmaKodu(String trim) {}
}


