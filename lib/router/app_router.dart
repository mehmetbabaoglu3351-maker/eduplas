// lib/router/app_router.dart
import 'package:flutter/material.dart';

import 'package:eduplas/router/route_names.dart';

// Geçit (auth durumuna göre yönlendirme)
import 'package:eduplas/ozellikler/gecit/kimlik_gecidi.dart';

// Giriş / Kayıt akışı
import 'package:eduplas/ozellikler/giris/giris_sayfasi.dart';
import 'package:eduplas/ozellikler/kayit/kayit_sayfasi.dart';
import 'package:eduplas/ozellikler/kayit/telefon_dogrulama_sayfasi.dart';
import 'package:eduplas/ozellikler/kayit/sms_kurtarma_sayfasi.dart';
import 'package:eduplas/ozellikler/kayit/rol_secimi_sayfasi.dart';
import 'package:eduplas/ozellikler/kayit/ilgi_secimi_sayfasi.dart';

// Hukuk
import 'package:eduplas/hukuk/uyelik_sozlesmesi_sayfasi.dart';
import 'package:eduplas/hukuk/gizlilik_sayfasi.dart';
import 'package:eduplas/hukuk/aydinlatma_sayfasi.dart';
import 'package:eduplas/hukuk/acik_riza_sayfasi.dart';
import 'package:eduplas/ozellikler/onay/sozlesme_kabul_sayfasi.dart';

// Kullanıcı
import 'package:eduplas/ozellikler/kullanici/kullanici_sayfasi.dart';

// Onay listesi
import 'package:eduplas/ozellikler/onay/onay_sayfasi.dart';

/// 🔴 main.dart içinde `onGenerateRoute: appRouter` dediğin fonksiyon BU.
/// Buradaki switch’e yazdığımız her rota çalışacak.
Route<dynamic> appRouter(RouteSettings settings) {
  switch (settings.name) {
    // 🔴 KÖK: HER ZAMAN KİMLİK GEÇİDİ
    case '/':
      return MaterialPageRoute(
        builder: (_) => const KimlikGecidi(),
        settings: settings,
      );

    // Giriş
    case RouteNames.giris:
      return MaterialPageRoute(
        builder: (_) => const GirisSayfasi(),
        settings: settings,
      );

    // Kayıt
    case '/kayit':
      return MaterialPageRoute(
        builder: (_) => const KayitSayfasi(),
        settings: settings,
      );

    // Telefon OTP
    //case RouteNames.otp:
      //return MaterialPageRoute(
        //builder: (_) => const TelefonDogrulamaSayfasi(),
        //settings: settings,
      //);

    // OTP kurtarma/mock
    case '/sms_kurtarma':
      return MaterialPageRoute(
        builder: (_) => const SmsKurtarmaSayfasi(),
        settings: settings,
      );

    // Rol seçimi
    case '/rol_sec':
      return MaterialPageRoute(
        builder: (_) => const RolSecimiSayfasi(),
        settings: settings,
      );

    // İlgi seçimi
    case '/ilgi_sec':
      return MaterialPageRoute(
        builder: (_) => const IlgiSecimiSayfasi(),
        settings: settings,
      );

    // HUKUK SAYFALARI
    case '/hukuk/uyelik':
      return MaterialPageRoute(
        builder: (_) => const UyelikSozlesmesiSayfasi(),
        settings: settings,
      );
    case '/hukuk/gizlilik':
      return MaterialPageRoute(
        builder: (_) => const GizlilikSayfasi(),
        settings: settings,
      );
    case '/hukuk/aydinlatma':
      return MaterialPageRoute(
        builder: (_) => const AydinlatmaSayfasi(),
        settings: settings,
      );
    case '/hukuk/acik_riza':
      return MaterialPageRoute(
        builder: (_) => const AcikRizaSayfasi(),
        settings: settings,
      );

    // Toplu sözleşme kabul
    case RouteNames.sozlesmeKabul:
      return MaterialPageRoute(
        builder: (_) => const SozlesmeKabulSayfasi(),
        settings: settings,
      );

    // Kullanıcı sayfası
    case RouteNames.user:
      return MaterialPageRoute(
        builder: (_) => const KullaniciSayfasi(),
        settings: settings,
      );

    // Onay kutusu
    case '/onaylar':
      return MaterialPageRoute(
        builder: (_) => const OnaySayfasi(),
        settings: settings,
      );

    // 404 fallback
    default:
      return MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('EduPlas')),
          body: Center(
            child: Text('404 — Rota bulunamadı (${settings.name})'),
          ),
        ),
        settings: settings,
      );
  }
}
