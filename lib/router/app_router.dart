// lib/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:eduplas/router/route_names.dart';

// Ekranlar
import 'package:eduplas/ozellikler/giris/giris_sayfasi.dart';
import 'package:eduplas/ozellikler/kayit/telefon_dogrulama_sayfasi.dart'; // artık e-posta kayıt sayfası
import 'package:eduplas/ozellikler/kayit/rol_secimi_sayfasi.dart';
import 'package:eduplas/ozellikler/kayit/ilgi_secimi_sayfasi.dart';
import 'package:eduplas/ozellikler/onay/sozlesme_kabul_sayfasi.dart';
import 'package:eduplas/ozellikler/kullanici/kullanici_sayfasi.dart';

// Not: Telefon doğrulama akışı devre dışı, e-posta ile kayıt geçerli.
Route<dynamic>? appRouter(RouteSettings settings) {
  switch (settings.name) {
    case '/':
    case RouteNames.giris:
      return MaterialPageRoute(builder: (_) => const GirisSayfasi());

    // E-posta ile kayıt (eski telefon doğrulama sayfası)
    case RouteNames.otp:
      return MaterialPageRoute(builder: (_) => const EmailRegisterSayfasi());

    case RouteNames.rolSec:
      return MaterialPageRoute(builder: (_) => const RolSecimiSayfasi());

    case RouteNames.ilgiSec:
      return MaterialPageRoute(builder: (_) => const IlgiSecimiSayfasi());

    case RouteNames.sozlesmeKabul:
      return MaterialPageRoute(builder: (_) => const SozlesmeKabulSayfasi());

    case RouteNames.user:
      return MaterialPageRoute(builder: (_) => const KullaniciSayfasi());

    default:
      return MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Sayfa bulunamadı')),
          body: Center(
            child: Text('Bilinmeyen rota: ${settings.name}'),
          ),
        ),
      );
  }
}
