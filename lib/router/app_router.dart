// lib/router/app_router.dart
import 'package:eduplas/ozellikler/kayit/kayit_sayfasi.dart';
import 'package:flutter/material.dart';

import 'package:eduplas/router/route_names.dart';

// EKRANLAR
import 'package:eduplas/ozellikler/giris/giris_sayfasi.dart';
import 'package:eduplas/ozellikler/kayit/telefon_dogrulama_sayfasi.dart';
import 'package:eduplas/ozellikler/onay/sozlesme_kabul_sayfasi.dart';
import 'package:eduplas/ozellikler/kullanici/kullanici_sayfasi.dart';
import 'package:eduplas/ayarlar/dil_secimi_sayfasi.dart';

// Kayıt sihirbazı adımları
import 'package:eduplas/ozellikler/kayit/rol_secimi_sayfasi.dart';
import 'package:eduplas/ozellikler/kayit/ilgi_secimi_sayfasi.dart';

// Hukuk
import 'package:eduplas/hukuk/sozlesme_okuma_sayfasi.dart';

// A1 – SMS kurtarma (mock)
import 'package:eduplas/ozellikler/kayit/sms_kurtarma_sayfasi.dart';
import 'package:eduplas/cekirdek/arayuz/app_logo.dart';

Route<dynamic> onGenerateAppRoute(RouteSettings settings) {
  switch (settings.name) {
    // KÖK
    case RouteNames.root:
      return MaterialPageRoute(
        builder: (_) => const GirisSayfasi(),
        settings: settings,
      );

    // GİRİŞ
    case RouteNames.giris:
      return MaterialPageRoute(
        builder: (_) => const GirisSayfasi(),
        settings: settings,
      );

    // OTP / Telefon doğrulama (A1: login | register | recovery)
    case RouteNames.otp:
      return MaterialPageRoute(
        builder: (_) => const TelefonDogrulamaSayfasi(),
        settings: settings,
      );

    // HUKUK KABUL
    case RouteNames.sozlesmeKabul:
      return MaterialPageRoute(
        builder: (_) => const SozlesmeKabulSayfasi(),
        settings: settings,
      );

    // HUKUK DETAY (asset'ten okuyan)
    case RouteNames.hukukiGenelSozlesme:
      return MaterialPageRoute(
        builder: (_) => const SozlesmeOkumaSayfasi(),
        settings: settings,
      );

    // KULLANICI SAYFASI
    case RouteNames.user:
      return MaterialPageRoute(
        builder: (_) => const KullaniciSayfasi(),
        settings: settings,
      );

    // DİL AYARLARI
    case RouteNames.dilAyar:
      return MaterialPageRoute(
        builder: (_) => const DilSecimiSayfasi(),
        settings: settings,
      );
case RouteNames.kayit:
  return MaterialPageRoute(
    builder: (_) => const KayitSayfasi(),   // senin var olan kayıt formun
    settings: settings,
  );

    // KAYIT ADIMLARI
    case RouteNames.rolSec:
      return MaterialPageRoute(
        builder: (_) => const RolSecimiSayfasi(),
        settings: settings,
      );

    case RouteNames.ilgiSec:
      return MaterialPageRoute(
        builder: (_) => const IlgiSecimiSayfasi(),
        settings: settings,
      );

    // A1 – SMS KURTARMA (mock)
    case RouteNames.smsKurtarma:
      return MaterialPageRoute(
        builder: (_) => const SmsKurtarmaSayfasi(),
        settings: settings,
      );

    // 404
    default:
      return MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Sayfa bulunamadı')),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppLogo(daire: true, compactHint: true),
                const SizedBox(height: 8),
                const Text(
                  'EduPlas',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF00BFA5),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Öğren, kazan; Öğret, kazandır.',
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 12),
                Text('Sayfa yok: ${settings.name}'),
              ],
            ),
          ),
        ),
        settings: settings,
      );
  }
}
