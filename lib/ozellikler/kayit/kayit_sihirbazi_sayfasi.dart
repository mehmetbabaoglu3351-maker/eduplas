// ignore_for_file: use_build_context_synchronously
// lib/ozellikler/kayit/kayit_sihirbazi_sayfasi.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../hizmetler/auth_servisi.dart';
import '../onay/onay_servisi.dart';
import '../../cekirdek/veri/yerveri_servisi.dart';
import '../../cekirdek/veri/yer_model.dart';

const double _currentPhase = 0.1;

class KayitSihirbaziSayfasi extends StatefulWidget {
  static const route = '/kayit_wizard';
  const KayitSihirbaziSayfasi({super.key});

  @override
  State<KayitSihirbaziSayfasi> createState() => _KayitSihirbaziSayfasiState();
}

class _KayitSihirbaziSayfasiState extends State<KayitSihirbaziSayfasi> {
  final _formKeys = List.generate(4, (_) => GlobalKey<FormState>());

  int _step = 0;

  // Hesap
  final _nick = TextEditingController();
  final _tel = TextEditingController();
  final _pw1 = TextEditingController();
  final _pw2 = TextEditingController();

  // Konum
  late final YerVeriServisi _yerSvc;
  bool _yerHazirlaniyor = true;
  String? _hata;

  String? _ilSlug, _ilKod;
  String? _ilceSlug, _ilceKod;
  String? _mahalleSlug, _mahalleKod;

  List<Il> _iller = const [];
  List<Ilce> _ilceler = const [];
  List<Mahalle> _mahalleler = const [];

  final _ilKey = GlobalKey<FormFieldState<String>>();
  final _ilceKey = GlobalKey<FormFieldState<String>>();
  final _mahalleKey = GlobalKey<FormFieldState<String>>();
  final _okul = TextEditingController();

  // Profil
  final _adSoyad = TextEditingController();
  String? _cinsiyet;
  String? _egitim;
  final _meslek = TextEditingController();
  String? _dil;
  final Set<String> _ilgiler = <String>{};

  // Özet
  String? _rol; // zorunlu
  bool _sozlesmeOnay = false; // zorunlu

  bool _islem = false;

  // Rol seçenekleri (senaryoya göre)
  static const _roller = <String>[
    'Öğrenci',
    'Öğretmen',
    'Koordinatör',
    'İl Admini',
    'Ülke Admini',
    'Admin',
    'Baş Admin',
    'İşyeri',
    'Destekçi',
  ];

  static const _ilgiSecenekleri = <String>[
    'Matematik',
    'Fen',
    'Kodlama',
    'Robotik',
    'Yapay Zekâ',
    'Yabancı Dil',
    'Edebiyat',
    'Tarih',
    'Coğrafya',
    'Sanat',
    'Müzik',
    'Spor',
    'Satranç',
    'Girişimcilik',
    'Psikoloji',
  ];

  @override
  void initState() {
    super.initState();
    _yerSvc = YerVeriServisi();
    _hazirlaYerVerisi();

    // Özet alanları canlı güncellensin
    _nick.addListener(_safeRefresh);
    _tel.addListener(_safeRefresh);
    _okul.addListener(_safeRefresh);
    _adSoyad.addListener(_safeRefresh);
    _meslek.addListener(_safeRefresh);
  }

  void _safeRefresh() {
    if (mounted) setState(() {});
  }

  Future<void> _hazirlaYerVerisi() async {
    try {
      await _yerSvc.hazirla();
      if (!mounted) return;
      setState(() {
        _iller = (_yerSvc.iller).cast<Il>().toList(growable: false);
        _yerHazirlaniyor = false;
        if (_iller.isEmpty) {
          _hata = 'İl verisi boş. JSON ve asset yollarını kontrol edin.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _yerHazirlaniyor = false;
        _hata = 'Konum verisi yüklenemedi: $e';
      });
    }
  }

  @override
  void dispose() {
    _nick.removeListener(_safeRefresh);
    _tel.removeListener(_safeRefresh);
    _okul.removeListener(_safeRefresh);
    _adSoyad.removeListener(_safeRefresh);
    _meslek.removeListener(_safeRefresh);

    _nick.dispose();
    _tel.dispose();
    _pw1.dispose();
    _pw2.dispose();
    _okul.dispose();
    _adSoyad.dispose();
    _meslek.dispose();
    super.dispose();
  }

  String _temizTakmaAd(String input) {
    var s = input.trim().toLowerCase();
    s = s
        .replaceAll('ç', 'c')
        .replaceAll('ğ', 'g')
        .replaceAll('ı', 'i')
        .replaceAll('i̇', 'i')
        .replaceAll('ö', 'o')
        .replaceAll('ş', 's')
        .replaceAll('ü', 'u');
    s = s.replaceAll(RegExp(r'\s+'), '.');
    s = s.replaceAll(RegExp(r'[^a-z0-9._-]'), '');
    s = s.replaceAll(RegExp(r'\.{2,}'), '.');
    s = s.replaceAll(RegExp(r'^\.'), '');
    s = s.replaceAll(RegExp(r'\.$'), '');
    if (s.isEmpty) s = 'kullanici';
    if (s.length < 3) s = '${s}___'.substring(0, 3);
    return s;
  }

  String generateEduPlasEmail(String takmaAd) {
    final s = _temizTakmaAd(takmaAd);
    return '$s@edu.plas';
  }

  bool _gecerliTelefon(String v) {
    final t = v.replaceAll(RegExp(r'[^0-9]'), '');
    return t.length >= 10 && t.length <= 13;
  }

  bool _isBasAdmin(String role) {
    final r = role.toLowerCase();
    return r.contains('baş admin') || r.contains('bas admin') || r == 'baş admin' || r == 'bas admin';
  }

  Future<void> _ilSecildi(String slug) async {
    final il = _iller.firstWhere((e) => e.slug == slug);
    _ilSlug = il.slug;

    _ilKod = null; // modelde yoksa null
    _ilceler = il.ilceler;
    _ilceSlug = null;
    _ilceKod = null;

    _mahalleler = const [];
    _mahalleSlug = null;
    _mahalleKod = null;

    _ilceKey.currentState?.reset();
    _mahalleKey.currentState?.reset();
    setState(() {});
  }

  Future<void> _ilceSecildi(String slug) async {
    final ilce = _ilceler.firstWhere((e) => e.slug == slug);
    _ilceSlug = ilce.slug;

    _ilceKod = null;
    _mahalleler = ilce.mahalleler;
    _mahalleSlug = null;
    _mahalleKod = null;

    _mahalleKey.currentState?.reset();
    setState(() {});
  }

  Future<void> _ileri() async {
    final ok = _formKeys[_step].currentState?.validate() ?? false;
    if (!ok) return;
    if (_step < 3) setState(() => _step += 1);
  }

  void _geri() {
    if (_step > 0) setState(() => _step -= 1);
  }

  Future<void> _kaydiTamamla() async {
    final ok = _formKeys[3].currentState?.validate() ?? false;
    final roleOk = (_rol != null && _rol!.trim().isNotEmpty);
    final contractOk = _sozlesmeOnay;
    if (!ok || !roleOk || !contractOk) return;

    if (_ilSlug == null || _ilceSlug == null || _mahalleSlug == null) {
      setState(() => _hata = 'Lütfen il/ilçe/mahalle seçin');
      return;
    }

    setState(() {
      _islem = true;
      _hata = null;
    });

    try {
      final temizNick = _temizTakmaAd(_nick.text);
      final tel = _tel.text.trim();

      await AuthServisi().kayitOl(
        takmaAd: temizNick,
        sifre: _pw1.text,
        telefon: tel.isEmpty ? null : tel,
      );

      final uid = FirebaseAuth.instance.currentUser!.uid;
      final requestedRole = (_rol ?? 'Öğrenci').trim();

      final regRef = FirebaseFirestore.instance.collection('registrations').doc(uid);
      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

      final ilAd = _iller.firstWhere((e) => e.slug == _ilSlug!).ad;
      final ilceAd = _ilceler.firstWhere((e) => e.slug == _ilceSlug!).ad;
      final mahalleAd = _mahalleler.firstWhere((e) => e.slug == _mahalleSlug!).ad;

      final adSoyad = _adSoyad.text.trim();
      final cinsiyet = _cinsiyet?.trim() ?? '';
      final egitim = _egitim?.trim() ?? '';
      final meslek = _meslek.text.trim();
      final dil = _dil?.trim() ?? '';
      final okul = _okul.text.trim();
      final ilgiler = _ilgiler.toList()..sort();

      final yerKoku = YerKoku(
        ilKod: _ilKod ?? '',
        ilSlug: _ilSlug!,
        ilceKod: _ilceKod,
        ilceSlug: _ilceSlug,
        mahalleKod: _mahalleKod,
        mahalleSlug: _mahalleSlug,
      );

      final baseReg = {
        'uid': uid,
        'takmaAd': temizNick,
        'telefon': tel,
        'requestedRole': requestedRole,
        'il': ilAd,
        'ilSlug': _ilSlug,
        'ilKod': _ilKod,
        'ilce': ilceAd,
        'ilceSlug': _ilceSlug,
        'ilceKod': _ilceKod,
        'mahalle': mahalleAd,
        'mahalleSlug': _mahalleSlug,
        'mahalleKod': _mahalleKod,
        'okul': okul,
        'profil': {
          'adSoyad': adSoyad,
          'cinsiyet': cinsiyet,
          'egitim': egitim,
          'meslek': meslek,
          'dil': dil,
        },
        'ilgiler': ilgiler,
        'yerKoku': yerKoku.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Her kullanıcı için QR alanı
      final qrPayload = {
        'ver': 1,
        'fmt': 'plain',     // ileride 'svg' / 'png' üretimi cihazda
        'data': 'EP:$uid',  // minimum: uygulama şeması + uid
      };

      if (_isBasAdmin(requestedRole)) {
        await userRef.set({
          'uid': uid,
          'takmaAd': temizNick,
          'role': 'Baş Admin',
          'telefon': tel,
          'il': ilAd,
          'ilSlug': _ilSlug,
          'ilKod': _ilKod,
          'ilce': ilceAd,
          'ilceSlug': _ilceSlug,
          'ilceKod': _ilceKod,
          'mahalle': mahalleAd,
          'mahalleSlug': _mahalleSlug,
          'mahalleKod': _mahalleKod,
          'okul': okul,
          'profil': {
            'adSoyad': adSoyad,
            'cinsiyet': cinsiyet,
            'egitim': egitim,
            'meslek': meslek,
            'dil': dil,
          },
          'ilgiler': ilgiler,
          'yerKoku': yerKoku.toMap(),
          'qr': qrPayload, // ✅ QR
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        await regRef.set({
          ...baseReg,
          'status': 'approved',
          'approverUid': uid,
          'approvedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else {
        await userRef.set({
          'uid': uid,
          'takmaAd': temizNick,
          'telefon': tel,
          'il': ilAd,
          'ilSlug': _ilSlug,
          'ilKod': _ilKod,
          'ilce': ilceAd,
          'ilceSlug': _ilceSlug,
          'ilceKod': _ilceKod,
          'mahalle': mahalleAd,
          'mahalleSlug': _mahalleSlug,
          'mahalleKod': _mahalleKod,
          'okul': okul,
          'profil': {
            'adSoyad': adSoyad,
            'cinsiyet': cinsiyet,
            'egitim': egitim,
            'meslek': meslek,
            'dil': dil,
          },
          'ilgiler': ilgiler,
          'yerKoku': yerKoku.toMap(),
          'qr': qrPayload, // ✅ QR
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        await regRef.set({
          ...baseReg,
          'status': 'pending',
          'approverUid': null,
        }, SetOptions(merge: true));

        // MOCK onay zinciri: uygun onaylayıcı ataması
        await OnayServisi().kaydaOnaylayiciAtaVeyaOtoOnayla(registrationUid: uid);
      }

      if (tel.isNotEmpty) {
        Navigator.pushReplacementNamed(context, '/telefon_dogrulama', arguments: tel);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Başvurun kaydedildi.')),
        );
        final popped = await Navigator.maybePop(context);
        if (!popped) {
          // Navigator.of(context).pushNamedAndRemoveUntil('/giris', (route) => false);
        }
      }
    } catch (e) {
      setState(() => _hata = e.toString());
    } finally {
      if (mounted) setState(() => _islem = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = [
      _AdimKart(
        baslik: 'Hesap',
        altBaslik: 'Takma ad, şifre, telefon',
        formKey: _formKeys[0],
        child: _adimHesap(),
      ),
      _AdimKart(
        baslik: 'Konum',
        altBaslik: 'İl → İlçe → Mahalle, okul',
        formKey: _formKeys[1],
        child: _yerHazirlaniyor ? const _YerLoading() : _adimKonum(),
      ),
      _AdimKart(
        baslik: 'Profil',
        altBaslik: 'Temel bilgiler ve ilgi alanları',
        formKey: _formKeys[2],
        child: _adimProfil(),
      ),
      _AdimKart(
        baslik: 'Özet + Sözleşme',
        altBaslik: 'Rol seçimi ve onay',
        formKey: _formKeys[3],
        child: _adimOzetSozlesme(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kayıt Sihirbazı'),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _AdimGosterge(aktif: _step, toplam: 4),
                const SizedBox(height: 12),
                if (_hata != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(_hata!, style: const TextStyle(color: Colors.red)),
                  ),
                Expanded(child: steps[_step]),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _step == 0 ? null : _geri,
                        child: const Text('Geri'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (_step < 3)
                      Expanded(
                        child: FilledButton(
                          onPressed: _islem ? null : _ileri,
                          child: _islem
                              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('İleri'),
                        ),
                      )
                    else
                      Expanded(
                        child: FilledButton(
                          onPressed: _islem ? null : _kaydiTamamla,
                          child: _islem
                              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Kaydı tamamla'),
                        ),
                      ),
                  ],
                ),
                if (_currentPhase < 0.2)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Aşama: 0.1 • Onaycı Seçimi bir sonraki sürümde açılacak.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _adimHesap() {
    return ListView(
      shrinkWrap: true,
      children: [
        TextFormField(
          controller: _nick,
          decoration: const InputDecoration(labelText: 'Takma ad'),
          validator: (v) {
            final s = _temizTakmaAd(v ?? '');
            if (s.isEmpty) return 'Gerekli';
            if (s.length < 3) return 'En az 3 karakter';
            return null;
          },
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _tel,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Telefon',
            hintText: '05xx xxx xx xx',
          ),
          validator: (v) {
            final t = (v ?? '').trim();
            if (t.isEmpty) return 'Telefon zorunlu';
            return _gecerliTelefon(t) ? null : 'Telefon formatı hatalı';
          },
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _pw1,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Şifre (min 6)'),
          validator: (v) => (v == null || v.length < 6) ? 'En az 6 karakter' : null,
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _pw2,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Şifre (tekrar)'),
          validator: (v) {
            if (v == null || v.length < 6) return 'En az 6 karakter';
            if (v != _pw1.text) return 'Şifreler uyuşmuyor';
            return null;
          },
        ),
        const SizedBox(height: 4),
        Builder(
          builder: (context) {
            final email = generateEduPlasEmail(_nick.text);
            return Text('Kurumsal e-posta: $email', style: Theme.of(context).textTheme.bodySmall);
          },
        ),
      ],
    );
  }

  Widget _adimKonum() {
    return ListView(
      shrinkWrap: true,
      children: [
        _SearchableSelect(
          key: _ilKey,
          labelText: 'İl',
          initialValue: _ilSlug,
          options: _iller.map((e) => _Option(value: e.slug, label: e.ad)).toList(growable: false),
          enabled: _iller.isNotEmpty,
          validator: (v) => (v == null || v.isEmpty) ? 'İl gerekli' : null,
          onChanged: (slug) => slug == null ? null : _ilSecildi(slug),
        ),
        const SizedBox(height: 10),
        _SearchableSelect(
          key: _ilceKey,
          labelText: 'İlçe',
          initialValue: _ilceSlug,
          options: _ilceler.map((e) => _Option(value: e.slug, label: e.ad)).toList(growable: false),
          enabled: _ilceler.isNotEmpty,
          validator: (v) => (v == null || v.isEmpty) ? 'İlçe gerekli' : null,
          onChanged: (slug) => slug == null ? null : _ilceSecildi(slug),
        ),
        const SizedBox(height: 10),
        _SearchableSelect(
          key: _mahalleKey,
          labelText: 'Mahalle',
          initialValue: _mahalleSlug,
          options: _mahalleler.map((m) => _Option(value: m.slug, label: m.ad)).toList(growable: false),
          enabled: _mahalleler.isNotEmpty,
          validator: (v) => (v == null || v.isEmpty) ? 'Mahalle gerekli' : null,
          onChanged: (slug) {
            if (slug == null) return;
            setState(() {
              _mahalleSlug = slug;
              _mahalleKod = null;
            });
          },
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _okul,
          decoration: const InputDecoration(labelText: 'Okul (opsiyonel)'),
        ),
        if (_iller.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'İl verisi boş. “assets/veri/yerler/tr.json” dosyasını doğrulayın.',
              style: TextStyle(fontSize: 12, color: Colors.redAccent),
            ),
          ),
      ],
    );
  }

  Widget _adimProfil() {
    return ListView(
      shrinkWrap: true,
      children: [
        TextFormField(
          controller: _adSoyad,
          decoration: const InputDecoration(labelText: 'Ad Soyad'),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Gerekli' : null,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _cinsiyet,
                decoration: const InputDecoration(labelText: 'Cinsiyet (opsiyonel)'),
                items: const [
                  DropdownMenuItem(value: 'Kadın', child: Text('Kadın')),
                  DropdownMenuItem(value: 'Erkek', child: Text('Erkek')),
                  DropdownMenuItem(value: 'Diğer', child: Text('Diğer')),
                  DropdownMenuItem(value: 'Belirtmek istemiyorum', child: Text('Belirtmek istemiyorum')),
                ],
                onChanged: (v) => setState(() => _cinsiyet = v),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _egitim,
                decoration: const InputDecoration(labelText: 'Eğitim (opsiyonel)'),
                items: const [
                  DropdownMenuItem(value: 'İlköğretim', child: Text('İlköğretim')),
                  DropdownMenuItem(value: 'Lise', child: Text('Lise')),
                  DropdownMenuItem(value: 'Önlisans', child: Text('Önlisans')),
                  DropdownMenuItem(value: 'Lisans', child: Text('Lisans')),
                  DropdownMenuItem(value: 'Y.Lisans', child: Text('Y.Lisans')),
                  DropdownMenuItem(value: 'Doktora', child: Text('Doktora')),
                ],
                onChanged: (v) => setState(() => _egitim = v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _meslek,
                decoration: const InputDecoration(labelText: 'Meslek (opsiyonel)'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _dil,
                decoration: const InputDecoration(labelText: 'Dil tercihi (opsiyonel)'),
                items: const [
                  DropdownMenuItem(value: 'Türkçe', child: Text('Türkçe')),
                  DropdownMenuItem(value: 'English', child: Text('English')),
                ],
                onChanged: (v) => setState(() => _dil = v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text('İlgi Alanları (opsiyonel)'),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _ilgiSecenekleri.map((etiket) {
            final secili = _ilgiler.contains(etiket);
            return FilterChip(
              label: Text(etiket),
              selected: secili,
              onSelected: (_) {
                setState(() {
                  if (secili) {
                    _ilgiler.remove(etiket);
                  } else {
                    _ilgiler.add(etiket);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _adimOzetSozlesme() {
    return ListView(
      shrinkWrap: true,
      children: [
        _grupBaslik('Özet'),
        _ozetSatiri('Takma ad', _temizTakmaAd(_nick.text)),
        _ozetSatiri('Kurumsal e-posta', generateEduPlasEmail(_nick.text)),
        _ozetSatiri('Telefon', _tel.text.isEmpty ? '-' : _tel.text),
        _ozetSatiri('İl', _ilSlug == null ? '-' : _iller.firstWhere((e) => e.slug == _ilSlug!).ad),
        _ozetSatiri('İlçe', _ilceSlug == null ? '-' : _ilceler.firstWhere((e) => e.slug == _ilceSlug!).ad),
        _ozetSatiri('Mahalle', _mahalleSlug == null ? '-' : _mahalleler.firstWhere((e) => e.slug == _mahalleSlug!).ad),
        _ozetSatiri('Okul', _okul.text.isEmpty ? '-' : _okul.text),
        _ozetSatiri('Ad Soyad', _adSoyad.text.isEmpty ? '-' : _adSoyad.text),
        const SizedBox(height: 12),
        const Divider(),
        const SizedBox(height: 12),

        _grupBaslik('Rol Seçimi (zorunlu)'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _roller.map((rol) {
            final secili = _rol == rol;
            return ChoiceChip(
              label: Text(rol),
              selected: secili,
              onSelected: (_) => setState(() => _rol = rol),
            );
          }).toList(),
        ),
        if (_rol == null)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text('Lütfen bir rol seçin.', style: TextStyle(color: Colors.red, fontSize: 12)),
          ),

        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 12),

        _grupBaslik('Sözleşme (zorunlu)'),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'EduPlas Kullanım Şartları ve KVKK özeti: Hizmeti adil, güvenli ve yasal '
            'çerçevede kullanmayı kabul edersiniz. Kişisel verileriniz, aydınlatma '
            'metnindeki amaçlarla işlenir. Devam etmek için onay vermeniz gerekir.',
            textAlign: TextAlign.start,
          ),
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Okudum, anladım ve kabul ediyorum.'),
          value: _sozlesmeOnay,
          onChanged: (v) => setState(() => _sozlesmeOnay = v ?? false),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        if (!_sozlesmeOnay)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              'Sözleşmeyi onaylamadan devam edemezsiniz.',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  static Widget _grupBaslik(String t) =>
      Text(t, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700));

  static Widget _ozetSatiri(String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            SizedBox(width: 140, child: Text('$k:')),
            Expanded(child: Text(v, style: const TextStyle(fontWeight: FontWeight.w600))),
          ],
        ),
      );
}

class _AdimKart extends StatelessWidget {
  final String baslik;
  final String altBaslik;
  final Widget child;
  final GlobalKey<FormState> formKey;

  const _AdimKart({
    required this.baslik,
    required this.altBaslik,
    required this.formKey,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(baslik, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(altBaslik, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 12),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdimGosterge extends StatelessWidget {
  final int aktif;
  final int toplam;

  const _AdimGosterge({required this.aktif, required this.toplam});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(toplam, (i) {
        final on = i == aktif;
        return Expanded(
          child: Container(
            height: 6,
            margin: EdgeInsets.only(right: i == toplam - 1 ? 0 : 6),
            decoration: BoxDecoration(
              color: on ? Theme.of(context).colorScheme.primary : Colors.black12,
              borderRadius: BorderRadius.circular(100),
            ),
          ),
        );
      }),
    );
  }
}

class _Option {
  final String value;
  final String label;
  const _Option({required this.value, required this.label});
}

class _SearchableSelect extends FormField<String> {
  _SearchableSelect({
    super.key,
    required String labelText,
    required List<_Option> options,
    super.initialValue,
    bool enabled = true,
    super.validator,
    ValueChanged<String?>? onChanged,
  }) : super(
          builder: (state) {
            final theme = Theme.of(state.context);
            final selected = options.where((o) => o.value == state.value).firstOrNull;
            final hasValue = selected != null;
            final border = OutlineInputBorder(borderRadius: BorderRadius.circular(8));

            Future<void> openPicker() async {
              if (!enabled) return;
              final result = await showModalBottomSheet<String>(
                context: state.context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (ctx) => _SearchSheet(
                  title: labelText,
                  options: options,
                  initialValue: state.value,
                ),
              );
              if (result != null) {
                state.didChange(result);
                onChanged?.call(result);
              }
            }

            return InkWell(
              onTap: openPicker,
              borderRadius: BorderRadius.circular(8),
              child: InputDecorator(
                isEmpty: !hasValue,
                decoration: InputDecoration(
                  labelText: labelText,
                  hintText: 'Seç…',
                  errorText: state.errorText,
                  enabled: enabled,
                  border: border,
                  enabledBorder: border,
                  focusedBorder: border.copyWith(
                    borderSide: const BorderSide(color: Color(0xFF00BFA5), width: 2),
                  ),
                  suffixIcon: IconButton(
                    tooltip: 'Seç',
                    icon: const Icon(Icons.search),
                    onPressed: enabled ? openPicker : null,
                  ),
                ),
                child: hasValue
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          selected.label,
                          style: TextStyle(
                            color: enabled ? theme.colorScheme.onSurface : theme.disabledColor,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            );
          },
        );
}

class _SearchSheet extends StatefulWidget {
  final String title;
  final List<_Option> options;
  final String? initialValue;

  const _SearchSheet({
    required this.title,
    required this.options,
    this.initialValue,
  });

  @override
  State<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<_SearchSheet> {
  final _q = TextEditingController();
  late List<_Option> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = widget.options;
    _q.addListener(_apply);
  }

  @override
  void dispose() {
    _q.removeListener(_apply);
    _q.dispose();
    super.dispose();
  }

  void _apply() {
    final t = _q.text.trim().toLowerCase();
    setState(() {
      _filtered = t.isEmpty
          ? widget.options
          : widget.options
              .where((o) => o.label.toLowerCase().contains(t) || o.value.toLowerCase().contains(t))
              .toList(growable: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.initialValue;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 4,
            width: 40,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Text(widget.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              ),
              IconButton(
                tooltip: 'Kapat',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _q,
            decoration: const InputDecoration(
              hintText: 'Ara...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 400),
            child: _filtered.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('Sonuç yok'),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final o = _filtered[i];
                      final isSel = o.value == selected;
                      return ListTile(
                        title: Text(o.label),
                        trailing: isSel ? const Icon(Icons.check) : null,
                        onTap: () => Navigator.pop(context, o.value),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

extension FirstOrNullExt<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class _YerLoading extends StatelessWidget {
  const _YerLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
