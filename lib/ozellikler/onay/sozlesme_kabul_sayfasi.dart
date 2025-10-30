// lib/ozellikler/onay/sozlesme_kabul_sayfasi.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:eduplas/router/route_names.dart';

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
  String? _assetMetin;
  bool _assetYukleniyor = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // 1) UID belirle
    if (_uid == null) {
      final user = FirebaseAuth.instance.currentUser;
      String? gelen = user?.uid;

      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map && args['uid'] is String) {
        gelen = args['uid'] as String;
      }

      gelen ??= 'dev_${DateTime.now().millisecondsSinceEpoch}';
      _uid = gelen;
    }

    // 2) Asset sözleşmeyi yükle
    _loadAsset();
  }

  Future<void> _loadAsset() async {
    try {
      final data = await DefaultAssetBundle.of(context).loadString('assets/sozlesme.txt');
      if (!mounted) return;
      setState(() {
        _assetMetin = data;
        _assetYukleniyor = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _assetMetin = 'Sözleşme metni yüklenemedi. Lütfen daha sonra tekrar deneyin.';
        _assetYukleniyor = false;
      });
    }
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

    // deterministik email
    final String email = _fakeEmailFrom(
      nick: snap.data()?['nick'] ?? snap.data()?['kullaniciAdi'],
      phone: phone,
      uid: _uid!,
    );

    // Firestore'a kesin yaz
    await docRef.set({
      'email': email,
      if (phone != null) 'telefon': phone,
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
      // Auth'a yazmayı Flutter tarafı yapmayacak, backend tamamlayacak
      'emailSyncedWithAuth': false,
      'emailPendingForAuthUpdate': email,
      'emailPendingReason': 'client_only_wrote_firestore',
      'emailPendingAt': now,
    }, SetOptions(merge: true));

    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sözleşme kaydedildi.'),
      ),
    );

    Navigator.of(context).pushReplacementNamed(RouteNames.user);
  }

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
        child: Column(
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
              child: _assetYukleniyor
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _assetMetin ?? '',
                        style: theme.textTheme.bodyMedium,
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
                            setState(() => _kabulEdildi = v ?? false);
                          },
                  ),
                  const Expanded(
                    child: Text('Metni okudum ve eduplas.club koşullarını kabul ediyorum.'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (!_kabulEdildi || _isSaving || _assetYukleniyor) ? null : _kabulIslemi,
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
}
