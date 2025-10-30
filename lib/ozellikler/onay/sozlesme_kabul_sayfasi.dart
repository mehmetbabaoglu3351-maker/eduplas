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

    // Auth updateEmail kaldırıldı (sürüm uyumsuzluğu)

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

  void _showHukukSheet(String baslik, String icerik) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: DraggableScrollableSheet(
            expand: false,
            maxChildSize: 0.9,
            initialChildSize: 0.8,
            minChildSize: 0.4,
            builder: (context, scrollController) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Text(
                      baslik,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(icerik),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Kapat'),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _hukukLink({
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: const TextStyle(
          decoration: TextDecoration.underline,
          color: Colors.blue,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.open_in_new, size: 20),
      onTap: onTap,
    );
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
                  // Linkli liste
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        _hukukLink(
                          title: '1) Üyelik / Kullanım Sözleşmesi',
                          onTap: () => _showHukukSheet('Üyelik / Kullanım Sözleşmesi', _sozlesme),
                        ),
                        _hukukLink(
                          title: '2) Gizlilik Politikası',
                          onTap: () => _showHukukSheet('Gizlilik Politikası', _gizlilik),
                        ),
                        _hukukLink(
                          title: '3) KVKK / Aydınlatma Metni',
                          onTap: () => _showHukukSheet('KVKK / Aydınlatma Metni', _aydinlatma),
                        ),
                        _hukukLink(
                          title: '4) Açık Rıza Metni',
                          onTap: () => _showHukukSheet('Açık Rıza Metni', _acikRiza),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
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
}
