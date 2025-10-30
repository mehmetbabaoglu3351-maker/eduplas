// lib/router/app_router.dart
import 'package:flutter/material.dart';

import 'package:eduplas/router/route_names.dart';

// Geçit (auth durumuna göre yönlendirme)
import 'package:eduplas/ozellikler/gecit/kimlik_gecidi.dart';

// Giriş & Kayıt
import 'package:eduplas/ozellikler/giris/giris_sayfasi.dart';
import 'package:eduplas/ozellikler/kayit/kayit_sayfasi.dart';

// Hukuk ekranları
import 'package:eduplas/hukuk/aydinlatma_sayfasi.dart';
import 'package:eduplas/hukuk/gizlilik_politikasi_sayfasi.dart';
import 'package:eduplas/hukuk/uyelik_sozlesmesi_sayfasi.dart';
import 'package:eduplas/hukuk/acik_riza_sayfasi.dart';

// Onay akışı
import 'package:eduplas/ozellikler/onay/sozlesme_kabul_sayfasi.dart';
import 'package:eduplas/ozellikler/onay/onay_sayfasi.dart';

// Kullanıcı ekranı (bizim hedef)
import 'package:eduplas/ozellikler/kullanici/kullanici_sayfasi.dart';

class AppRouter {
  AppRouter();

  Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final name = settings.name;

    // 1) KÖK → Kimlik Geçidi
    if (name == '/' || name == RouteNames.user) {
      return MaterialPageRoute(
        builder: (_) => const KimlikGecidi(),
        settings: settings,
      );
    }

    // 2) Giriş → sadece ilk kayıt/giriş formu
    if (name == RouteNames.giris) {
      return MaterialPageRoute(
        builder: (_) => const GirisSayfasi(),
        settings: settings,
      );
    }

    // 3) Kayıt → bizim büyük form
    if (name == '/kayit' || name == RouteNames.kayit) {
      return MaterialPageRoute(
        builder: (_) => const KayitSayfasi(),
        settings: settings,
      );
    }

    // 4) Hukuk ekranları (asset’ten okuyanlar)
    if (name == '/hukuk/aydinlatma') {
      return MaterialPageRoute(
        builder: (_) => const AydinlatmaSayfasi(),
        settings: settings,
      );
    }
    if (name == '/hukuk/gizlilik') {
      return MaterialPageRoute(
        builder: (_) => const GizlilikPolitikasiSayfasi(),
        settings: settings,
      );
    }
    if (name == '/hukuk/uyelik') {
      return MaterialPageRoute(
        builder: (_) => const UyelikSozlesmesiSayfasi(),
        settings: settings,
      );
    }
    if (name == '/hukuk/acik_riza') {
      return MaterialPageRoute(
        builder: (_) => const AcikRizaSayfasi(),
        settings: settings,
      );
    }

    // 5) Sözleşme kabul ekranı (akışta zorunlu)
    if (name == RouteNames.sozlesmeKabul || name == '/sozlesme_kabul') {
      return MaterialPageRoute(
        builder: (_) => const SozlesmeKabulSayfasi(),
        settings: settings,
      );
    }

    // 6) Onay listesi
    if (name == '/onaylarim') {
      return MaterialPageRoute(
        builder: (_) => const OnaySayfasi(),
        settings: settings,
      );
    }

    // 7) Kullanıcı infosu (profil ekranı)
    if (name == '/kullanici') {
      return MaterialPageRoute(
        builder: (_) => const KullaniciSayfasi(),
        settings: settings,
      );
    }

    // FALLBACK → yine geçide
    return MaterialPageRoute(
      builder: (_) => const KimlikGecidi(),
      settings: settings,
    );
  }
}
