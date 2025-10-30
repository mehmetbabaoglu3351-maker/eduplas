// lib/router/app_router.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:eduplas/router/route_names.dart';

// Ekranlar
import 'package:eduplas/ozellikler/giris/giris_sayfasi.dart';
import 'package:eduplas/ozellikler/kayit/telefon_dogrulama_sayfasi.dart';
import 'package:eduplas/ozellikler/onay/sozlesme_kabul_sayfasi.dart';
import 'package:eduplas/ozellikler/onay/sozlesme_onay_sayfasi.dart';
import 'package:eduplas/ozellikler/onay/onay_sayfasi.dart';
import 'package:eduplas/ozellikler/kullanici/kullanici_sayfasi.dart';
import 'package:eduplas/ayarlar/dil_secimi_sayfasi.dart';

// Yeni: rol/ilgi
import 'package:eduplas/ozellikler/kayit/rol_secimi_sayfasi.dart';
import 'package:eduplas/ozellikler/kayit/ilgi_secimi_sayfasi.dart';

class AppRouter {
  Route<dynamic> onGenerateRoute(RouteSettings settings) {
    debugPrint('[Router] onGenerateRoute -> ${settings.name}');

    switch (settings.name) {
      // Root'u /giris'e yönlendir
      case RouteNames.root:
      case RouteNames.giris:
        return MaterialPageRoute<void>(
          builder: (_) => const GirisSayfasi(),
          settings: settings,
        );

     // case RouteNames.otp:
       // return MaterialPageRoute<void>(
         // builder: (_) => const TelefonDogrulamaSayfasi(),
         // settings: settings,
       // );

      // Yeni akış
      case RouteNames.rolSec:
        return MaterialPageRoute<void>(
          builder: (_) => const RolSecimiSayfasi(),
          settings: settings,
        );

      case RouteNames.ilgiSec:
        return MaterialPageRoute<void>(
          builder: (_) => const IlgiSecimiSayfasi(),
          settings: settings,
        );

      case RouteNames.sozlesmeKabul:
        return MaterialPageRoute<void>(
          builder: (_) => const SozlesmeKabulSayfasi(),
          settings: settings,
        );

      // Hukuk / onay
      case RouteNames.legal:
        return MaterialPageRoute<void>(
          builder: (_) => const SozlesmeOnaySayfasi(),
          settings: settings,
        );

      case RouteNames.onay:
        return MaterialPageRoute<void>(
          builder: (_) => const OnaySayfasi(),
          settings: settings,
        );

      // Kullanıcı
      case RouteNames.user:
        return MaterialPageRoute<void>(
          builder: (_) => const KullaniciSayfasi(),
          settings: settings,
        );

      // Ayarlar
      case RouteNames.lang:
        return MaterialPageRoute<void>(
          builder: (_) => const DilSecimiSayfasi(),
          settings: settings,
        );

      // Bilinmeyen rota
      default:
        return MaterialPageRoute<void>(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Bilinmeyen Sayfa')),
            body: Center(
              child: Text('Tanımsız rota: ${settings.name ?? '-'}'),
            ),
          ),
          settings: settings,
        );
    }
  }
}
