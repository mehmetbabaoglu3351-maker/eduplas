// ignore_for_file: use_build_context_synchronously

// lib/ozellikler/kayit/kayit_sayfasi.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eduplas/cekirdek/konum/konum_adres_secici.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:eduplas/cekirdek/konum/konum_servisi.dart'; // LocationFix
import 'package:eduplas/hizmetler/auth_servisi.dart';
import 'package:eduplas/ozellikler/onay/onay_servisi.dart';
import 'package:eduplas/router/route_names.dart';

class KayitSayfasi extends StatefulWidget {
  static const route = '/kayit';
  const KayitSayfasi({super.key});

  @override
  State<KayitSayfasi> createState() => _KayitSayfasiState();
}

class _KayitSayfasiState extends State<KayitSayfasi> {
  final _formKey = GlobalKey<FormState>();

  // Versiyon etiketleri
  static const String _vSozlesme = 'soz_v1';
  static const String _vRiza = 'riza_v1';
  static const String _vAyd = 'ayd_v1';
  static const String _vGiz = 'gizlilik_v1';

  // Hesap alanları
  final _nick = TextEditingController();
  final _tel = TextEditingController();
  final _sifre = TextEditingController();
  final _sifre2 = TextEditingController();
  bool _obscure1 = true;
  bool _obscure2 = true;

  // Profil alanları (opsiyonel)
  final _okul = TextEditingController();
  final _adSoyad = TextEditingController();
  final _dogumTarihi = TextEditingController(); // yyyy-MM-dd
  String? _cinsiyet;
  String? _egitim;
  final _meslek = TextEditingController();
  String? _dil;

  // Sözleşmeler ve izinler
  bool _uyelikKabul = false; // zorunlu
  bool _acikRizaKabul = false; // zorunlu
  bool _aydinlatmaGosterildi = false; // link tıklanınca true
  bool _gizlilikGosterildi = false; // link tıklanınca true

  // ROL listesi — Baş Admin var!
  static const _roller = <String>[
    'Öğrenci',
    'Öğretmen',
    'Sınıf Başkanı',
    'Koordinatör',
    'İlçe Admin',
    'İl Admin',
    'Baş Admin', // <<< BURADA
    'Destekçi',
    'İşyeri', // senaryoda vardı
  ];
  String? _seciliRol = 'Öğrenci';

  // İlgi alanları
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
  final Set<String> _ilgiAlanlariSecili = <String>{};

  // Konum
  SeciliYer? _adres;
  LocationFix? _fix;

  // Diğer durumlar
  bool _islem = false;
  String? _hata;
  bool _bilgiOnayi = false;

  @override
  void initState() {
    super.initState();
    _nick.addListener(_clearError);
  }

  @override
  void dispose() {
    _nick
      ..removeListener(_clearError)
      ..dispose();
    _tel.dispose();
    _sifre.dispose();
    _sifre2.dispose();
    _okul.dispose();
    _adSoyad.dispose();
    _dogumTarihi.dispose();
    _meslek.dispose();
    super.dispose();
  }

  void _clearError() {
    if (_hata != null) {
      setState(() => _hata = null);
    }
  }

  // Basit slug
  String _slug(String input) {
    var s = input.trim().toLowerCase();
    s = s
        .replaceAll('ç', 'c')
        .replaceAll('ğ', 'g')
        .replaceAll('ı', 'i')
        .replaceAll('i̇', 'i')
        .replaceAll('ö', 'o')
        .replaceAll('ş', 's')
        .replaceAll('ü', 'u');
    s = s.replaceAll(RegExp(r'\s+'), '-');
    s = s.replaceAll(RegExp(r'[^a-z0-9._-]'), '');
    s = s
        .replaceAll(RegExp(r'-{2,}'), '-')
        .replaceAll(RegExp(r'^\-'), '')
        .replaceAll(RegExp(r'\-$'), '');
    return s;
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
    s = s
        .replaceAll(RegExp(r'\.{2,}'), '.')
        .replaceAll(RegExp(r'^\.'), '')
        .replaceAll(RegExp(r'\.$'), '');
    if (s.isEmpty) s = 'kullanici';
    if (s.length < 3) s = '${s}___'.substring(0, 3);
    return s;
  }

  // Telefon artık OPSİYONEL — sen öyle istedin
  bool _gecerliTelefonOpsiyonel(String v) {
    final t = v.replaceAll(RegExp(r'[^0-9]'), '');
    if (t.isEmpty) return true; // boşsa kabul
    return t.length == 10;
  }

  Future<void> _tarihSec(BuildContext context) async {
    final now = DateTime.now();
    final first = DateTime(now.year - 100, now.month, now.day);
    final last = DateTime(now.year, now.month, now.day);

    final secilen = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18, now.month, now.day),
      firstDate: first,
      lastDate: last,
      helpText: 'Doğum Tarihini Seç',
      cancelText: 'İptal',
      confirmText: 'Tamam',
      fieldHintText: 'gg/aa/yyyy',
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF00BFA5),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (secilen != null) {
      final y = '${secilen.year}'.padLeft(4, '0');
      final m = '${secilen.month}'.padLeft(2, '0');
      final d = '${secilen.day}'.padLeft(2, '0');
      _dogumTarihi.text = '$y-$m-$d';
      if (mounted) setState(() {});
    }
  }

  bool get _konumVar => _adres != null || _fix != null;

  Map<String, dynamic> _buildLocation() {
    final admin1 = _adres?.il ?? '';
    final admin2 = _adres?.ilce ?? '';
    final locality = _adres?.mahalle ?? '';
    final nowIso = DateTime.now().toIso8601String();

    final Map<String, dynamic> location = {
      'country': 'TR',
      'admin1': admin1,
      'admin2': admin2,
      'locality': locality,
      'sublocality': '',
      'slugs': {
        'admin1': _slug(admin1),
        'admin2': _slug(admin2),
        'locality': _slug(locality),
      },
      'codes': {
        'admin1': '',
        'admin2': '',
        'locality': '',
        'sublocality': '',
      },
      'source': _adres != null && _fix != null
          ? 'selection+device'
          : (_adres != null ? 'selection' : 'device'),
      'updatedAt': nowIso,
    };

    if (_fix != null) {
      location['deviceFix'] = {
        'lat': _fix!.lat,
        'lng': _fix!.lng,
        'accuracyM': _fix!.accuracyM,
        'source': _fix!.source,
        'at': _fix!.at.toIso8601String(),
      };
    }

    return location;
  }

  Future<void> _openLegal(String route, void Function() onOpenedFlag) async {
    try {
      await Navigator.of(context).pushNamed(route);
      onOpenedFlag();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hukuk sayfası yakında eklenecek.'),
          duration: Duration(seconds: 2),
        ),
      );
      onOpenedFlag();
    }
  }

  // Burası kilit yer
  Future<void> _kayit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_sifre.text != _sifre2.text) {
      setState(() => _hata = 'Şifreler uyuşmuyor.');
      return;
    }
    if (!_konumVar) {
      setState(() => _hata = 'Lütfen konum seçin veya cihazdan alın.');
      return;
    }
    if (!_uyelikKabul) {
      setState(() => _hata = 'Kullanıcı Sözleşmesini kabul etmelisiniz.');
      return;
    }
    if (!_acikRizaKabul) {
      setState(() => _hata = 'Açık Rıza metnini onaylamalısınız.');
      return;
    }
    if (!_bilgiOnayi) {
      setState(() => _hata = 'Bilgilerinizin doğruluğunu onaylayın.');
      return;
    }

    setState(() {
      _islem = true;
      _hata = null;
    });

    try {
      final temizNick = _temizTakmaAd(_nick.text);
      final tel = _tel.text.replaceAll(RegExp(r'[^0-9]'), ''); // opsiyonel
      final requestedRole = (_seciliRol ?? 'Öğrenci').trim();

      // 1) Email/password ile user oluştur
      await AuthServisi().kayitOl(
        takmaAd: temizNick,
        sifre: _sifre.text,
      );

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Kullanıcı oturumu açılamadı.');
      }
      final uid = user.uid;

      // Profil (opsiyoneller)
      final adSoyad = _adSoyad.text.trim();
      final dogum = _dogumTarihi.text.trim();
      final cinsiyet = _cinsiyet?.trim() ?? '';
      final egitim = _egitim?.trim() ?? '';
      final meslek = _meslek.text.trim();
      final dil = _dil?.trim() ?? '';
      final okul = _okul.text.trim();
      final ilgiler = _ilgiAlanlariSecili.toList()..sort();

      final db = FirebaseFirestore.instance;
      final regRef = db.collection('registrations').doc(uid);
      final userRef = db.collection('users').doc(uid);

      final agreementsReg = <String, dynamic>{
        'uyelik_sozlesmesi': {
          'accepted': true,
          'version': _vSozlesme,
          'date': FieldValue.serverTimestamp(),
        },
        'acik_riza': {
          'accepted': true,
          'version': _vRiza,
          'date': FieldValue.serverTimestamp(),
        },
        'aydinlatma': {
          'shown': _aydinlatmaGosterildi,
          'version': _vAyd,
          if (_aydinlatmaGosterildi) 'date': FieldValue.serverTimestamp(),
        },
        'gizlilik': {
          'shown': _gizlilikGosterildi,
          'version': _vGiz,
          if (_gizlilikGosterildi) 'date': FieldValue.serverTimestamp(),
        },
      };

      final location = _buildLocation();

      final baseReg = <String, dynamic>{
        'uid': uid,
        'takmaAd': temizNick,
        'telefon': tel,
        'requestedRole': requestedRole,
        'okul': okul,
        'profil': {
          'adSoyad': adSoyad,
          'dogumTarihi': dogum,
          'cinsiyet': cinsiyet,
          'egitim': egitim,
          'meslek': meslek,
          'dil': dil,
        },
        'ilgiler': ilgiler,
        'agreements': agreementsReg,
        'location': location,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final agreementsUser = <String, dynamic>{
        'uyelik_sozlesmesi': {
          'accepted': true,
          'version': _vSozlesme,
          'date': FieldValue.serverTimestamp(),
        },
        'acik_riza': {
          'accepted': true,
          'version': _vRiza,
          'date': FieldValue.serverTimestamp(),
        },
        'aydinlatma': {
          'shown': _aydinlatmaGosterildi,
          'version': _vAyd,
          if (_aydinlatmaGosterildi) 'date': FieldValue.serverTimestamp(),
        },
        'gizlilik': {
          'shown': _gizlilikGosterildi,
          'version': _vGiz,
          if (_gizlilikGosterildi) 'date': FieldValue.serverTimestamp(),
        },
      };

      final baseUser = <String, dynamic>{
        'uid': uid,
        'nickname': temizNick,
        'telefon': tel,
        'okul': okul,
        'profil': {
          'adSoyad': adSoyad,
          'dogumTarihi': dogum,
          'cinsiyet': cinsiyet,
          'egitim': egitim,
          'meslek': meslek,
          'dil': dil,
        },
        'ilgiler': ilgiler,
        'agreements': agreementsUser,
        'location': location,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final isBasAdmin = requestedRole.toLowerCase().contains('baş admin') ||
          requestedRole.toLowerCase().contains('bas admin');

      if (isBasAdmin) {
        await userRef.set({
          ...baseUser,
          'role': 'Bas Admin',
          'durum': 'legal_ok',
        }, SetOptions(merge: true));

        await regRef.set({
          ...baseReg,
          'status': 'approved',
          'approverUid': uid,
          'approvedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else {
        await userRef.set({
          ...baseUser,
          'role': requestedRole,
          'durum': 'legal_pending',
        }, SetOptions(merge: true));

        await regRef.set({
          ...baseReg,
          'status': 'pending',
          'approverUid': null,
        }, SetOptions(merge: true));
      }

      // MOCK OnayServisi
      final basvuru = Basvuru(
        uid: uid,
        takmaAd: temizNick,
        telefon: tel,
        requestedRole: requestedRole,
        location: location,
        okul: okul,
        status: isBasAdmin ? 'approved' : 'pending',
        profilAdSoyad: adSoyad.isEmpty ? null : adSoyad,
        createdAt: DateTime.now(),
      );

      OnayServisi().kayitEkleVeyaGuncelle(basvuru);
      await OnayServisi()
          .kaydaOnaylayiciAtaVeyaOtoOnayla(registrationUid: uid);

      if (!mounted) return;

      // 📌 ESKİ TELEFON EKRANI YOK!
      // Doğrudan kimlik geçidine gönderiyoruz
      Navigator.pushReplacementNamed(context, RouteNames.user);
    } catch (e) {
      if (!mounted) return;
      setState(() => _hata = e.toString());
    } finally {
      if (mounted) setState(() => _islem = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 10);

    return Scaffold(
      appBar: AppBar(title: const Text('Kayıt Ol')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Card(
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    if (_hata != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          _hata!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),

                    // --- Hesap ---
                    const _GrupBaslik('Hesap Bilgileri'),
                    TextFormField(
                      controller: _nick,
                      decoration: const InputDecoration(labelText: 'Takma ad'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Gerekli' : null,
                    ),
                    gap,

                    // Telefon artık OPSİYONEL
                    TextFormField(
                      controller: _tel,
                      decoration: const InputDecoration(
                        labelText: 'Telefon (opsiyonel)',
                        hintText: '5XX XXX XX XX',
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (v) => (v != null && _gecerliTelefonOpsiyonel(v))
                          ? null
                          : 'Telefon 10 hane olmalı (veya boş bırak).',
                    ),
                    gap,
                    TextFormField(
                      controller: _sifre,
                      decoration: InputDecoration(
                        labelText: 'Şifre',
                        suffixIcon: IconButton(
                          tooltip: 'Göster/Gizle',
                          icon: Icon(
                            _obscure1 ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () =>
                              setState(() => _obscure1 = !_obscure1),
                        ),
                      ),
                      obscureText: _obscure1,
                      validator: (v) =>
                          (v == null || v.length < 6) ? 'En az 6 karakter' : null,
                    ),
                    gap,
                    TextFormField(
                      controller: _sifre2,
                      decoration: InputDecoration(
                        labelText: 'Şifre (tekrar)',
                        suffixIcon: IconButton(
                          tooltip: 'Göster/Gizle',
                          icon: Icon(
                            _obscure2 ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () =>
                              setState(() => _obscure2 = !_obscure2),
                        ),
                      ),
                      obscureText: _obscure2,
                      validator: (v) =>
                          (v == null || v.length < 6) ? 'En az 6 karakter' : null,
                    ),

                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),

                    // --- Konum ---
                    const _GrupBaslik('Konum'),
                    KonumAdresSecici(
                      konumButonu: true,
                      onChanged: (secim, fix) {
                        setState(() {
                          _adres = secim;
                          _fix = fix;
                        });
                      },
                      bilgiMetni:
                          'Ülke → İl → İlçe → Mahalle seç veya “Cihazdan Al” ile otomatik doldur.',
                    ),

                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),

                    // --- Profil ---
                    const _GrupBaslik('Profil Bilgileri (opsiyonel)'),
                    TextFormField(
                      controller: _adSoyad,
                      decoration: const InputDecoration(labelText: 'Ad Soyad'),
                    ),
                    gap,
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                                labelText: 'Cinsiyet (opsiyonel)'),
                            items: const [
                              DropdownMenuItem(value: 'Kadın', child: Text('Kadın')),
                              DropdownMenuItem(value: 'Erkek', child: Text('Erkek')),
                              DropdownMenuItem(value: 'Diğer', child: Text('Diğer')),
                              DropdownMenuItem(
                                value: 'Belirtmek istemiyorum',
                                child: Text('Belirtmek istemiyorum'),
                              ),
                            ],
                            onChanged: (v) => setState(() => _cinsiyet = v),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration:
                                const InputDecoration(labelText: 'Eğitim (opsiyonel)'),
                            items: const [
                              DropdownMenuItem(
                                  value: 'İlköğretim', child: Text('İlköğretim')),
                              DropdownMenuItem(value: 'Lise', child: Text('Lise')),
                              DropdownMenuItem(
                                  value: 'Önlisans', child: Text('Önlisans')),
                              DropdownMenuItem(value: 'Lisans', child: Text('Lisans')),
                              DropdownMenuItem(value: 'Y.Lisans', child: Text('Y.Lisans')),
                              DropdownMenuItem(value: 'Doktora', child: Text('Doktora')),
                            ],
                            onChanged: (v) => setState(() => _egitim = v),
                          ),
                        ),
                      ],
                    ),
                    gap,
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _meslek,
                            decoration:
                                const InputDecoration(labelText: 'Meslek (opsiyonel)'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                                labelText: 'Dil tercihi (opsiyonel)'),
                            items: const [
                              DropdownMenuItem(value: 'Türkçe', child: Text('Türkçe')),
                              DropdownMenuItem(value: 'English', child: Text('English')),
                            ],
                            onChanged: (v) => setState(() => _dil = v),
                          ),
                        ),
                      ],
                    ),
                    gap,
                    TextFormField(
                      controller: _okul,
                      decoration: const InputDecoration(
                        labelText: 'Okul (opsiyonel)',
                      ),
                    ),
                    gap,
                    TextFormField(
                      controller: _dogumTarihi,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Doğum tarihi (opsiyonel)',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_today_outlined),
                          onPressed: () => _tarihSec(context),
                          tooltip: 'Tarih seç',
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),

                    // --- İlgi alanları ---
                    const _GrupBaslik('İlgi Alanları (opsiyonel)'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _ilgiSecenekleri.map((etiket) {
                        final secili = _ilgiAlanlariSecili.contains(etiket);
                        return FilterChip(
                          label: Text(etiket),
                          selected: secili,
                          onSelected: (_) {
                            setState(() {
                              if (secili) {
                                _ilgiAlanlariSecili.remove(etiket);
                              } else {
                                _ilgiAlanlariSecili.add(etiket);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),

                    // --- Rol ---
                    const _GrupBaslik('Rol Seçimi'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _roller.map((rol) {
                        final secili = _seciliRol == rol;
                        return ChoiceChip(
                          label: Text(rol),
                          selected: secili,
                          onSelected: (_) => setState(() {
                            _seciliRol = rol;
                            _bilgiOnayi = false;
                          }),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),

                    // --- Sözleşmeler ve İzinler ---
                    const _GrupBaslik('Sözleşmeler ve İzinler'),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => _openLegal(
                            '/hukuk/aydinlatma',
                            () => setState(() => _aydinlatmaGosterildi = true),
                          ),
                          child: const Text('Aydınlatma Metni'),
                        ),
                        const SizedBox(width: 12),
                        TextButton(
                          onPressed: () => _openLegal(
                            '/hukuk/gizlilik',
                            () => setState(() => _gizlilikGosterildi = true),
                          ),
                          child: const Text('Gizlilik Politikası'),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => _openLegal(
                            '/hukuk/uyelik',
                            () {},
                          ),
                          child: const Text('Kullanıcı Sözleşmesi'),
                        ),
                        const SizedBox(width: 12),
                        TextButton(
                          onPressed: () => _openLegal(
                            '/hukuk/acik_riza',
                            () {},
                          ),
                          child: const Text('Açık Rıza Metni'),
                        ),
                      ],
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _uyelikKabul,
                      onChanged: (v) => setState(() => _uyelikKabul = v ?? false),
                      title: const Text(
                        'Kullanıcı Sözleşmesini okudum ve kabul ediyorum.',
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _acikRizaKabul,
                      onChanged: (v) => setState(() => _acikRizaKabul = v ?? false),
                      title: const Text(
                        'Açık Rıza Metnini onaylıyorum.',
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),

                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 12),

                    // --- Özet ve Onay ---
                    const _GrupBaslik('Özet ve Onay'),
                    if (_adres != null)
                      _OzetSatiri(
                        'Konum Seçimi',
                        '${_adres!.il} / ${_adres!.ilce} / ${_adres!.mahalle}',
                      ),
                    if (_fix != null)
                      _OzetSatiri(
                        'Cihaz Konumu',
                        '${_fix!.lat.toStringAsFixed(6)}, '
                        '${_fix!.lng.toStringAsFixed(6)} '
                        '(~${(_fix!.accuracyM ?? 0).toStringAsFixed(1)} m)',
                      ),
                    _OzetSatiri('Rol', _seciliRol ?? 'Öğrenci'),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _bilgiOnayi,
                      onChanged: (v) => setState(() => _bilgiOnayi = v ?? false),
                      title: const Text(
                        'Bilgilerimin doğru olduğunu ve kaydımın işlenmesini onaylıyorum.',
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    const SizedBox(height: 8),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _islem ? null : _kayit,
                        child: _islem
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Kayıt Ol'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GrupBaslik extends StatelessWidget {
  final String text;
  const _GrupBaslik(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
    );
  }
}

class _OzetSatiri extends StatelessWidget {
  final String etiket;
  final String deger;
  const _OzetSatiri(this.etiket, this.deger);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(width: 140, child: Text('$etiket:')),
          Expanded(
            child: Text(
              deger,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
