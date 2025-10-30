// lib/ozellikler/onay/sozlesme_kabul_sayfasi.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:eduplas/router/route_names.dart';
import 'package:eduplas/cekirdek/hukuk/hukuk_servisi.dart';

class SozlesmeKabulSayfasi extends StatefulWidget {
  static const route = RouteNames.sozlesmeKabul;
  const SozlesmeKabulSayfasi({super.key});

  @override
  State<SozlesmeKabulSayfasi> createState() => _SozlesmeKabulSayfasiState();
}

class _SozlesmeKabulSayfasiState extends State<SozlesmeKabulSayfasi> {
  String? _uid;
  bool _isSaving = false;
  bool _kabulEdildi = false;

  // Yüklenen metinler
  String _sozlesme = '';
  String _gizlilik = '';
  String _aydinlatma = '';
  String _acikRiza = '';

  bool _loadingTexts = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // UID ayarı
    if (_uid == null) {
      final user = FirebaseAuth.instance.currentUser;
      String? gelen = user?.uid;
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map && args['uid'] is String) {
        gelen = args['uid'] as String;
      }
      // DEV fallback
      gelen ??= 'dev_${DateTime.now().millisecondsSinceEpoch}';
      _uid = gelen;
    }

    // Hukuk metinlerini yükle
    _loadHukukTexts();
  }

  Future<void> _loadHukukTexts() async {
    final locale = Localizations.localeOf(context);
    final dilKodu = locale.languageCode; // tr / en / ...
    final servis = HukukServisi.instance;

    final sozlesme = await servis.yukle(dilKodu, HukukTipi.sozlesme);
    final gizlilik = await servis.yukle(dilKodu, HukukTipi.gizlilik);
    final aydinlatma = await servis.yukle(dilKodu, HukukTipi.aydinlatma);
    final acikRiza = await servis.yukle(dilKodu, HukukTipi.acikRiza);

    if (!mounted) return;
    setState(() {
      _sozlesme = sozlesme;
      _gizlilik = gizlilik;
      _aydinlatma = aydinlatma;
      _acikRiza = acikRiza;
      _loadingTexts = false;
    });
  }

  Future<void> _kabulIslemi() async {
    if (_uid == null) return;
    if (_isSaving) return;

    setState(() => _isSaving = true);

    final firestore = FirebaseFirestore.instance;
    final docRef = firestore.collection('kullanicilar').doc(_uid);
    final snap = await docRef.get();

    final now = DateTime.now().toUtc().toIso8601String();
    final authUser = FirebaseAuth.instance.currentUser;
    final phone = authUser?.phoneNumber;

    // Email üretim kuralımız (deterministik)
    final String email = _fakeEmailFrom(
      nick: snap.data()?['nick'] ?? snap.data()?['kullaniciAdi'],
      phone: phone,
      uid: _uid!,
    );

    // Firestore'a yaz
    await docRef.set({
      'sozlesmeKabul': true,
      'sozlesmeKabulTarih': now,
      'gizlilikKabul': true,
      'gizlilikKabulTarih': now,
      'acikRizaKabul': true,
      'acikRizaKabulTarih': now,
      'konumKullanimiKabul': true,
      'konumKullanimiKabulTarih': now,
      'kayıtAsamalari': {
        'otp': true,
        'rol': true,
        'ilgi': true,
        'legal': true,
      },
      'email': email,
      if (phone != null) 'telefon': phone,
    }, SetOptions(merge: true));

    // ⚠️ NOT: Burada eskiden
    // await authUser.updateEmail(email);
    // yapıyorduk. Mevcut firebase_auth sürümünde görünmediği için kaldırdık.
    // Bundan sonra admin/Cloud Function Auth tarafını eşitler.

    if (!mounted) return;
    setState(() => _isSaving = false);
    Navigator.of(context).pushReplacementNamed(RouteNames.user);
  }

  // EDU: artık eduplas.club
  String _fakeEmailFrom({String? nick, String? phone, required String uid}) {
    String base;
    if (nick != null && nick.trim().isNotEmpty) {
      base = nick.trim().toLowerCase().replaceAll(' ', '_');
    } else if (phone != null && phone.trim().isNotEmpty) {
      base = phone.trim().replaceAll('+', '');
    } else {
      base = uid;
    }
    return '$base@eduplas.club';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sözleşme ve Aydınlatma'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _loadingTexts
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  const SizedBox(height: 10),
                  Text(
                    'EduPlas',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Öğren, kazan. Öğret, kazandır.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _hukukBolum('1) Üyelik / Kullanım Sözleşmesi', _sozlesme),
                          const SizedBox(height: 16),
                          _hukukBolum('2) Gizlilik Politikası', _gizlilik),
                          const SizedBox(height: 16),
                          _hukukBolum('3) KVKK / Aydınlatma Metni', _aydinlatma),
                          const SizedBox(height: 16),
                          _hukukBolum('4) Açık Rıza Metni', _acikRiza),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _kabulEdildi,
                          onChanged: _isSaving
                              ? null
                              : (v) {
                                  setState(() {
                                    _kabulEdildi = v ?? false;
                                  });
                                },
                        ),
                        const Expanded(
                          child: Text('Tüm metinleri okudum ve eduplas.club koşullarını kabul ediyorum.'),
                        )
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (!_kabulEdildi || _isSaving) ? null : _kabulIslemi,
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Kaydet ve Devam Et'),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _hukukBolum(String baslik, String icerik) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.grey.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(baslik, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(icerik),
          ],
        ),
      ),
    );
  }
}
