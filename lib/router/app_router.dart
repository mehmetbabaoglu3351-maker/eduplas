// lib/router/app_router.dart
import 'package:flutter/material.dart';

// Route isimleri
import 'package:eduplas/router/route_names.dart';

// Akış / kimlik / kayıt ekranları
import 'package:eduplas/ozellikler/giris/giris_sayfasi.dart';
import 'package:eduplas/ozellikler/kayit/kayit_sayfasi.dart';
import 'package:eduplas/ozellikler/kayit/rol_secimi_sayfasi.dart';
import 'package:eduplas/ozellikler/kayit/ilgi_secimi_sayfasi.dart';
import 'package:eduplas/ozellikler/kayit/telefon_dogrulama_sayfasi.dart';

// Hukuk ekranları
import 'package:eduplas/ozellikler/onay/sozlesme_kabul_sayfasi.dart';
import 'package:eduplas/ozellikler/onay/onay_sayfasi.dart';
import 'package:eduplas/hukuk/aydinlatma_sayfasi.dart';
import 'package:eduplas/hukuk/gizlilik_sayfasi.dart';
import 'package:eduplas/hukuk/uyelik_sozlesmesi_sayfasi.dart';
import 'package:eduplas/hukuk/acik_riza_sayfasi.dart';

// Kullanıcı ekranı
import 'package:eduplas/ozellikler/kullanici/kullanici_sayfasi.dart';

// Rol bazlı ana sayfalar
import 'package:eduplas/ozellikler/rol_ana/bas_admin_paneli.dart';
import 'package:eduplas/ozellikler/rol_ana/il_admin_paneli.dart';
import 'package:eduplas/ozellikler/rol_ana/ilce_admin_paneli.dart';
import 'package:eduplas/ozellikler/rol_ana/ogretmen_paneli.dart';
import 'package:eduplas/ozellikler/rol_ana/ogrenci_anasayfasi.dart';
import 'package:eduplas/ozellikler/rol_ana/koordinator_paneli.dart';
import 'package:eduplas/ozellikler/rol_ana/destekci_paneli.dart';
import 'package:eduplas/ozellikler/rol_ana/isyeri_paneli.dart';

// Ayarlar
import 'package:eduplas/ayarlar/dil_secimi_sayfasi.dart';

Route<dynamic> appRouter(RouteSettings settings) {
  switch (settings.name) {
    // KÖK / GİRİŞ
    case RouteNames.giris:
    case '/':
      return MaterialPageRoute(
        builder: (_) => const GirisSayfasi(),
        settings: settings,
      );

    // KAYIT
    case RouteNames.kayit:
      return MaterialPageRoute(
        builder: (_) => const KayitSayfasi(),
        settings: settings,
      );

    

    // KAYIT sihirbazı alt adımlar
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

    // HUKUK BLOĞU
    case RouteNames.sozlesmeKabul:
      return MaterialPageRoute(
        builder: (_) => const SozlesmeKabulSayfasi(),
        settings: settings,
      );
    case RouteNames.onay:
      return MaterialPageRoute(
        builder: (_) => const OnaySayfasi(),
        settings: settings,
      );
    case RouteNames.hukukAydinlatma:
      return MaterialPageRoute(
        builder: (_) => const AydinlatmaSayfasi(),
        settings: settings,
      );
    case RouteNames.hukukGizlilik:
      return MaterialPageRoute(
        builder: (_) => const GizlilikSayfasi(),
        settings: settings,
      );
    case RouteNames.hukukUyelik:
      return MaterialPageRoute(
        builder: (_) => const UyelikSozlesmesiSayfasi(),
        settings: settings,
      );
    case RouteNames.hukukAcikRiza:
      return MaterialPageRoute(
        builder: (_) => const AcikRizaSayfasi(),
        settings: settings,
      );

    // KULLANICI
    case RouteNames.user:
      return MaterialPageRoute(
        builder: (_) => const KullaniciSayfasi(),
        settings: settings,
      );

    // AYARLAR
    case RouteNames.lang:
      return MaterialPageRoute(
        builder: (_) => const DilSecimiSayfasi(),
        settings: settings,
      );

    // ROL SAYFALARI (sabit path'ler — şu anlık dışarıdan da çağrılabilir)
    case '/rol/bas_admin':
      return MaterialPageRoute(
        builder: (_) => const BasAdminPaneli(),
        settings: settings,
      );
    case '/rol/il_admin':
      return MaterialPageRoute(
        builder: (_) => const IlAdminPaneli(),
        settings: settings,
      );
    case '/rol/ilce_admin':
      return MaterialPageRoute(
        builder: (_) => const IlceAdminPaneli(),
        settings: settings,
      );
    case '/rol/ogretmen':
      return MaterialPageRoute(
        builder: (_) => const OgretmenPaneli(),
        settings: settings,
      );
    case '/rol/ogrenci':
      return MaterialPageRoute(
        builder: (_) => const OgrenciAnasayfasi(),
        settings: settings,
      );
    case '/rol/koordinator':
      return MaterialPageRoute(
        builder: (_) => const KoordinatorPaneli(),
        settings: settings,
      );
    case '/rol/destekci':
      return MaterialPageRoute(
        builder: (_) => const DestekciPaneli(),
        settings: settings,
      );
    case '/rol/isyeri':
      return MaterialPageRoute(
        builder: (_) => const IsyeriPaneli(),
        settings: settings,
      );

    // 404
    default:
      return MaterialPageRoute(
        builder: (_) => _NotFoundPage(routeName: settings.name ?? '—'),
        settings: settings,
      );
  }
}

class _NotFoundPage extends StatelessWidget {
  final String routeName;
  const _NotFoundPage({required this.routeName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('404 — Sayfa yok')),
      body: Center(
        child: Text('İstenen rota bulunamadı: $routeName'),
      ),
    );
  }
}
