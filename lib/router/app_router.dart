// lib/router/app_router.dart
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

Route<dynamic> onGenerateAppRoute(RouteSettings settings) {
  switch (settings.name) {
    case RouteNames.root:
      return MaterialPageRoute(
        builder: (_) => const GirisSayfasi(),
        settings: settings,
      );

    case RouteNames.giris:
      return MaterialPageRoute(
        builder: (_) => const GirisSayfasi(),
        settings: settings,
      );

    case RouteNames.otp: // 🔴 eksik olan kısım
      return MaterialPageRoute(
        builder: (_) => const TelefonDogrulamaSayfasi(),
        settings: settings,
      );

    case RouteNames.sozlesmeKabul:
      return MaterialPageRoute(
        builder: (_) => const SozlesmeKabulSayfasi(),
        settings: settings,
      );

    case RouteNames.user:
      return MaterialPageRoute(
        builder: (_) => const KullaniciSayfasi(),
        settings: settings,
      );

    case RouteNames.dilAyar:
      return MaterialPageRoute(
        builder: (_) => const DilSecimiSayfasi(),
        settings: settings,
      );

    // Kayıt akış adımları
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

    // 404
    default:
      return MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('404')),
          body: Center(
            child: Text('Sayfa yok: ${settings.name}'),
          ),
        ),
        settings: settings,
      );
  }
}
