// lib/router/app_router.dart
import 'package:flutter/material.dart';

// Geçit (auth durumuna göre yönlendirme)
import 'package:eduplas/ozellikler/gecit/kimlik_gecidi.dart';

// Giriş / Kayıt
import 'package:eduplas/ozellikler/giris/giris_sayfasi.dart';
import 'package:eduplas/ozellikler/kayit/kayit_sayfasi.dart';
import 'package:eduplas/ozellikler/kayit/telefon_dogrulama_sayfasi.dart';

// Hukuk
import 'package:eduplas/ozellikler/onay/sozlesme_kabul_sayfasi.dart';
import 'package:eduplas/hukuk/uyelik_sozlesmesi_sayfasi.dart';
import 'package:eduplas/hukuk/acik_riza_sayfasi.dart';
import 'package:eduplas/hukuk/aydinlatma_sayfasi.dart';
import 'package:eduplas/hukuk/gizlilik_sayfasi.dart';

// Kullanıcı
import 'package:eduplas/ozellikler/kullanici/kullanici_sayfasi.dart';

// Rol ana sayfaları (emniyet için)
import 'package:eduplas/ozellikler/rol_ana/bas_admin_paneli.dart';
import 'package:eduplas/ozellikler/rol_ana/il_admin_paneli.dart';
import 'package:eduplas/ozellikler/rol_ana/ilce_admin_paneli.dart';
import 'package:eduplas/ozellikler/rol_ana/ogretmen_paneli.dart';
import 'package:eduplas/ozellikler/rol_ana/ogrenci_anasayfasi.dart';
import 'package:eduplas/ozellikler/rol_ana/koordinator_paneli.dart';
import 'package:eduplas/ozellikler/rol_ana/destekci_paneli.dart';
import 'package:eduplas/ozellikler/rol_ana/isyeri_paneli.dart';

Route<dynamic> appRouter(RouteSettings settings) {
  switch (settings.name) {
    // KÖK: auth durumuna göre yönlendirme
    case '/':
      return MaterialPageRoute(
        builder: (_) => const KimlikGecidi(),
        settings: settings,
      );

    // GİRİŞ
    case '/giris':
      return MaterialPageRoute(
        builder: (_) => const GirisSayfasi(),
        settings: settings,
      );

    // KAYIT (senin uzun formun)
    case '/kayit':
      return MaterialPageRoute(
        builder: (_) => const KayitSayfasi(),
        settings: settings,
      );

    // OTP / Telefon doğrulama
    // Şu anda telefon akışını “devre dışı” gibi kullanıyoruz ama
    // bazı sayfalar hala /otp veya /telefon_dogrulama diye gitmeye çalışıyor.
    // O yüzden bu route kesin OLMALI.
    

    // HUKUK — linkli gösterim
    case '/sozlesme_kabul':
      return MaterialPageRoute(
        builder: (_) => const SozlesmeKabulSayfasi(),
        settings: settings,
      );
    case '/hukuk/uyelik':
      return MaterialPageRoute(
        builder: (_) => const UyelikSozlesmesiSayfasi(),
        settings: settings,
      );
    case '/hukuk/acik_riza':
      return MaterialPageRoute(
        builder: (_) => const AcikRizaSayfasi(),
        settings: settings,
      );
    case '/hukuk/aydinlatma':
      return MaterialPageRoute(
        builder: (_) => const AydinlatmaSayfasi(),
        settings: settings,
      );
    case '/hukuk/gizlilik':
      return MaterialPageRoute(
        builder: (_) => const GizlilikSayfasi(),
        settings: settings,
      );

    // Kullanıcı ana
    case '/user':
      return MaterialPageRoute(
        builder: (_) => const KullaniciSayfasi(),
        settings: settings,
      );

    // Emniyet: rol panelleri direkt açılabilir olsun
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
  }

  // VAR OLMAYAN ROUTE → basit 404
  return MaterialPageRoute(
    builder: (_) => Scaffold(
      appBar: AppBar(title: const Text('404')),
      body: Center(
        child: Text('Route bulunamadı: ${settings.name}'),
      ),
    ),
    settings: settings,
  );
}
