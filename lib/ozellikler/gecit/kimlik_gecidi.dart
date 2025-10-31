// lib/ozellikler/gecit/kimlik_gecidi.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// Akış sayfaları
import '../giris/giris_sayfasi.dart';
import '../onay/onay_sayfasi.dart';
import '../beklemede/beklemede_sayfasi.dart';
import '../onay/sozlesme_kabul_sayfasi.dart';
import '../kayit/kayit_sayfasi.dart'; // kayıt yoksa buraya gideceğiz

// Rol bazlı ana sayfalar
import '../rol_ana/ogrenci_anasayfasi.dart';
import '../rol_ana/ogretmen_paneli.dart';
import '../rol_ana/koordinator_paneli.dart';
import '../rol_ana/ilce_admin_paneli.dart';
import '../rol_ana/il_admin_paneli.dart';
import '../rol_ana/bas_admin_paneli.dart';
import '../rol_ana/destekci_paneli.dart';
import '../rol_ana/isyeri_paneli.dart';

// ROUTE isimleri
import 'package:eduplas/router/route_names.dart';

class KimlikGecidi extends StatefulWidget {
  const KimlikGecidi({super.key});

  @override
  State<KimlikGecidi> createState() => _KimlikGecidiState();
}

class _KimlikGecidiState extends State<KimlikGecidi> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool _profilOlusturuluyor = false;
  bool _navigating = false;

  Future<void> _ensureUserProfileFromRegistration({
    required String uid,
    required Map<String, dynamic> reg,
  }) async {
    if (_profilOlusturuluyor) return;
    _profilOlusturuluyor = true;

    try {
      final usersRef = _db.collection('users').doc(uid);
      final snapshot = await usersRef.get();
      if (snapshot.exists) return;

      // Rol yoksa ilk kullanıcı baş admin olsun
      final existing = await _db.collection('users').get();
      final isFirstUser = existing.size == 0;
      final requestedRole =
          (reg['requestedRole'] ?? reg['roleIntent'] ?? '').toString();
      final role = isFirstUser
          ? 'bas_admin'
          : (requestedRole.isNotEmpty ? requestedRole : 'ogrenci');

      await usersRef.set({
        'uid': uid,
        'takmaAd': reg['takmaAd'] ?? '',
        'role': role,
        'telefon': reg['telefon'] ?? '',
        'il': reg['il'] ?? '',
        'ilce': reg['ilce'] ?? '',
        'mahalle': reg['mahalle'] ?? '',
        'okul': reg['okul'] ?? '',
        'profil': reg['profil'] ?? <String, dynamic>{},
        'ilgiler': reg['ilgiler'] ?? <dynamic>[],
        'durum': 'approved',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Profil oluşturma hatası: $e');
    } finally {
      _profilOlusturuluyor = false;
    }
  }

  Widget _sayfaFromRole(String role) {
    final r = role.toLowerCase().trim();
    if (r.contains('bas_admin')) return const BasAdminPaneli();
    if (r.contains('ulke_admin') || r.contains('ülke admin')) {
      return const IlAdminPaneli();
    }
    if (r.contains('il_admin') || r.contains('il admin')) {
      return const IlAdminPaneli();
    }
    if (r.contains('ilce_admin') || r.contains('ilçe admin')) {
      return const IlceAdminPaneli();
    }
    if (r.contains('koordinator')) return const KoordinatorPaneli();
    if (r.contains('ogretmen')) return const OgretmenPaneli();
    if (r.contains('destekci')) return const DestekciPaneli();
    if (r.contains('isyeri')) return const IsyeriPaneli();
    return const OgrenciAnasayfasi();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (ctx, authSnap) {
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const _LoadingScaffold();
        }

        final user = authSnap.data;
        // 1) Kullanıcı yoksa → Giriş
        if (user == null) {
          return const GirisSayfasi();
        }

        final uid = user.uid;
        final regRef = _db.collection('registrations').doc(uid);
        final userRef = _db.collection('users').doc(uid);

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: regRef.snapshots(),
          builder: (ctx, regSnap) {
            if (regSnap.connectionState == ConnectionState.waiting) {
              return const _LoadingScaffold();
            }

            final regExists = regSnap.hasData && regSnap.data!.exists;
            final reg = regExists
                ? (regSnap.data!.data() ?? <String, dynamic>{})
                : <String, dynamic>{};
            final status = (reg['status'] ?? '').toString();

            return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: userRef.snapshots(),
              builder: (ctx, userSnap) {
                if (userSnap.connectionState == ConnectionState.waiting) {
                  return const _LoadingScaffold();
                }

                final userDocExists =
                    userSnap.hasData && userSnap.data!.exists;
                final userDoc = userDocExists
                    ? (userSnap.data!.data() ?? <String, dynamic>{})
                    : <String, dynamic>{};
                var role = (userDoc['role'] ?? '').toString().trim();

                // 2) Kayıt yoksa → KAYIT SAYFASI
                if (!regExists && !userDocExists) {
                  return const KayitSayfasi();
                }

                // Firestore durum alanı
                final durum = (userDoc['durum'] ?? '').toString();

                // 3) Hukuk kontrolü — tek sözleşme
                final bool sozlesmeKabul =
                    userDoc['sozlesmeKabul'] == true;

                if (!sozlesmeKabul && !_navigating) {
                  _navigating = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Navigator.of(context).pushReplacementNamed(
                      RouteNames.sozlesmeKabul,
                      arguments: uid,
                    );
                  });
                  return const _LoadingScaffold();
                }

                // 4) registration durumu
                if (regExists) {
                  if (status == 'pending') {
                    return const BeklemedeSayfasi(
                      baslik: 'Onay bekleniyor',
                      aciklama:
                          'Başvurun ilgili onaylayıcıya iletildi. Lütfen beklemede kal.',
                      reddedildi: false,
                    );
                  }

                  if (status == 'rejected') {
                    return const BeklemedeSayfasi(
                      baslik: 'Başvurun reddedildi',
                      aciklama:
                          'Yeni başvuru yapabilir veya destek alabilirsin.',
                      reddedildi: true,
                    );
                  }

                  if (status == 'approved' && !userDocExists) {
                    _ensureUserProfileFromRegistration(uid: uid, reg: reg);
                    return const _LoadingScaffold();
                  }
                }

                // 5) rol belirle
                if (role.isEmpty) {
                  role = (reg['requestedRole'] ?? reg['roleIntent'] ?? 'ogrenci')
                      .toString()
                      .trim();
                }

                // 6) Son: rol ekranına git
                return _sayfaFromRole(role);
              },
            );
          },
        );
      },
    );
  }
}

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
