// lib/cekirdek/akis/route_gate.dart
import 'package:flutter/foundation.dart';

/// Senaryo v1.1 akış bayrakları.
/// Ekranlar ilgili adım tamamlanınca bu bayrakları true yapar.
class RouteGate {
  RouteGate._();

  static bool otpOk = false;        // OTP tamamlandı
  static bool rolIntentOk = false;  // rol niyeti yazıldı (registrations)
  static bool ilgiOk = false;       // ilgi seçimi tamamlandı (registrations)
  static bool legalOk = false;      // sözleşmeler kabul edildi (registrations)

  /// Hedef rotaya girmeden önce gerekli basamaklar tamam mı?
  static bool allow({required String targetRoute}) {
    switch (targetRoute) {
      case '/rol_sec':
        return otpOk;
      case '/ilgi_sec':
        return otpOk && rolIntentOk;
      case '/sozlesme_kabul':
        return otpOk && rolIntentOk && ilgiOk;
      case '/user':
        return otpOk && rolIntentOk && ilgiOk && legalOk;
      default:
        return true;
    }
  }

  static void dump() {
    debugPrint('[RouteGate] otp=$otpOk, rol=$rolIntentOk, ilgi=$ilgiOk, legal=$legalOk');
  }
}


