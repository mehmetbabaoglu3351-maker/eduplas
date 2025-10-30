// lib/ozellikler/gecit/kimlik_gecidi.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// Akış sayfaları
import '../giris/giris_sayfasi.dart';
import '../onay/onay_sayfasi.dart';
import '../beklemede/beklemede_sayfasi.dart';
import '../onay/sozlesme_kabul_sayfasi.dart'; // LEGAL kontrol için

// Rol bazlı ana sayfalar
import '../rol_ana/ogrenci_anasayfasi.dart';
import '../rol_ana/ogretmen_paneli.dart';
import '../rol_ana/koordinator_paneli.dart';
import '../rol_ana/ilce_admin_paneli.dart';
import '../rol_ana/il_admin_paneli.dart';
import '../rol_ana/bas_admin_paneli.dart';
import '../rol_ana/destekci_paneli.dart';
import '../rol_ana/isyeri_paneli.dart';

// ROUTE isimleri (sözleşmeye argümanla gidebilmek için)
import 'package:eduplas/router/route_names.dart';

// Bizim MOCK hukuk onaylarını tutan servis
import 'package:eduplas/ozellikler/onay/onay_servisi.dart';
import 'package:eduplas/cekirdek/hukuk/legal_versiyonlar.dart';

class KimlikGecidi extends StatefulWidget {
  const KimlikGecidi({super.key});

  @override
  State<KimlikGecidi> createState() => _KimlikGecidiState();
}

class _KimlikGecidiState extends State<KimlikGecidi> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool _profilOlusturuluyor = false;
  bool _legalYonlendirildi = false; // aynı frame'de birden fazla kez push etmesin

  Future<void> _ensureUserProfileFromRegistration({
    required String uid,
    required Map<String, dynamic> reg,
  }) async {
    if (_profilOlusturuluyor) return;
    _profilOlusturuluyor = true;

    try {
      final usersRef = _db.collection('users').doc(uid);
      final u = await usersRef.get();
      if (u.exists) return;

      final requestedRole =
          (reg['requestedRole'] ?? reg['roleIntent'] ?? '').toString();

      await usersRef.set({
        'uid': uid,
        'takmaAd': reg['takmaAd'] ?? '',
        'role': requestedRole,
        'telefon': reg['telefon'] ?? '',
        'il': reg['il'] ?? '',
        'ilce': reg['ilce'] ?? '',
        'mahalle': reg['mahalle'] ?? '',
        'okul': reg['okul'] ?? '',
        'profil': reg['profil'] ?? <String, dynamic>{},
        'ilgiler': reg['ilgiler'] ?? <dynamic>[],
        // 🤜 dikkat: burada default'u "legal_pending"
        'durum': reg['durum'] ?? 'legal_pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Sessiz geç
    } finally {
      _profilOlusturuluyor = false;
    }
  }

  Widget _sayfaFromRole(String role) {
    final r = role.toLowerCase().trim();

    if (r.contains('baş admin') || r.contains('bas admin') || r == 'bas_admin') {
      return const BasAdminPaneli();
    }
    if (r.contains('ülke admin') || r.contains('ulke admin') || r == 'ulke_admin') {
      return const IlAdminPaneli(); // Ülke/İl ayrımı gelecekte panel ayrışabilir
    }
    if (r.contains('ilçe admin') || r.contains('ilce admin') || r == 'ilce_admin') {
      return const IlceAdminPaneli();
    }
    if (r.contains('il admin') || r == 'il_admin') {
      return const IlAdminPaneli();
    }
    if (r.contains('koordinatör') || r.contains('koordinator') || r == 'koordinator') {
      return const KoordinatorPaneli();
    }
    if (r.contains('öğretmen') || r.contains('ogretmen') || r == 'ogretmen') {
      return const OgretmenPaneli();
    }
    if (r.contains('destekçi') || r.contains('destekci') || r == 'destekci') {
      return const DestekciPaneli();
    }
    if (r.contains('işyeri') || r.contains('isyeri') || r == 'isyeri') {
      return const IsyeriPaneli();
    }
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
        if (user == null) return const GirisSayfasi();

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

                // 1) Firestore'daki durum
                final durum = (userDoc['durum'] ?? '').toString();

                // 2) MOCK hukuk servisi üzerinden de kontrol et
                final onayServ = OnayServisi.instance;
                final mockLegalOk = onayServ.kullaniciZorunluHukuklariTamMi(
                  uid: uid,
                  dokumanlar: LegalVersiyonlar.dokumanlar,
                );

                // Şayet Firestore "legal_pending" dese bile, mock servis "tamam" diyorsa,
                // kullanıcıyı artık sözleşmeye kilitlemeyelim.
                final gercektenLegalOk = durum == 'legal_ok' || mockLegalOk;

                if (!gercektenLegalOk) {
                  // Aynı frame'de pushReplacementNamed'i birden fazla kez çağırmamak için
                  if (!_legalYonlendirildi) {
                    _legalYonlendirildi = true;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Navigator.of(context).pushReplacementNamed(
                        RouteNames.sozlesmeKabul,
                        arguments: uid,
                      );
                    });
                  }
                  // Geçici loading göster
                  return const _LoadingScaffold();
                }

                if (!regExists) {
                  return const _Placeholder(
                    baslik: 'Kayıt eksik',
                    aciklama:
                        'Kayıt bilgilerin eksik görünüyor. Lütfen kaydı tamamla veya tekrar giriş yap.',
                  );
                }

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

                if (status == 'approved') {
                  if (!userDocExists) {
                    _ensureUserProfileFromRegistration(uid: uid, reg: reg);
                    return const _LoadingScaffold();
                  }
                  // Emniyet: role boş ise registration’dan al (eski/yeniyi destekle)
                  if (role.isEmpty) {
                    role = (reg['requestedRole'] ?? reg['roleIntent'] ?? '')
                        .toString()
                        .trim();
                  }
                  return _sayfaFromRole(role);
                }

                return const _Placeholder(
                  baslik: 'Durum okunamadı',
                  aciklama: 'Beklenmedik durum. Lütfen tekrar deneyin.',
                );
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

class _Placeholder extends StatelessWidget {
  final String baslik;
  final String aciklama;
  const _Placeholder({required this.baslik, required this.aciklama});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('EduPlas')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Card(
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.info_outline, size: 64),
                  const SizedBox(height: 12),
                  Text(
                    baslik,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    aciklama,
                    style: const TextStyle(fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const OnaySayfasi()),
                      );
                    },
                    icon: const Icon(Icons.verified),
                    label: const Text('Onaylarım'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
