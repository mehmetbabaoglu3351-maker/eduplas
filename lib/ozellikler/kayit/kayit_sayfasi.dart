// ignore_for_file: use_build_context_synchronously

// lib/ozellikler/kayit/kayit_sayfasi.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eduplas/cekirdek/konum/konum_adres_secici.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:eduplas/cekirdek/konum/konum_servisi.dart';
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
  final _nick = TextEditingController();
  final _email = TextEditingController();
  final _sifre = TextEditingController();
  final _sifre2 = TextEditingController();
  bool _islem = false;
  String? _hata;
  String? _seciliRol;
  bool _uyelikKabul = false;
  bool _acikRizaKabul = false;
  bool _bilgiOnayi = false;

  SeciliYer? _adres;
  LocationFix? _fix;

  static const _roller = <String>[
    'Öğrenci',
    'Öğretmen',
    'Koordinatör',
    'İlçe Admin',
    'İl Admin',
    'Baş Admin',
    'Destekçi',
  ];

   Map<String, dynamic> _buildLocation() {
    final nowIso = DateTime.now().toIso8601String();
    return {
      'country': 'TR',
      'admin1': _adres?.il ?? '',
      'admin2': _adres?.ilce ?? '',
      'locality': _adres?.mahalle ?? '',
      'source': _fix != null ? 'device' : 'manual',
      'updatedAt': nowIso,
    };
  }

  Future<void> _kayit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_sifre.text != _sifre2.text) {
      setState(() => _hata = 'Şifreler uyuşmuyor.');
      return;
    }
    if (!_uyelikKabul || !_acikRizaKabul) {
      setState(() => _hata = 'Tüm sözleşmeleri onaylayın.');
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
      final db = FirebaseFirestore.instance;
      final auth = FirebaseAuth.instance;

      // 🔹 1. Auth oluştur (email/password)
      final cred = await auth.createUserWithEmailAndPassword(
        email: _email.text.trim(),
        password: _sifre.text,
      );
      final uid = cred.user!.uid;

      // 🔹 2. Kullanıcı sayısı kontrol (ilk kullanıcı = Baş Admin)
      final allUsers = await db.collection('users').get();
      final isFirstUser = allUsers.size == 0;
      final requestedRole =
          _seciliRol ?? (isFirstUser ? 'Baş Admin' : 'Öğrenci');

      final role = isFirstUser ? 'Baş Admin' : requestedRole;
      final status = isFirstUser ? 'approved' : 'pending';

      // 🔹 3. Firestore kayıtları
      final location = _buildLocation();
      final regRef = db.collection('registrations').doc(uid);
      final userRef = db.collection('users').doc(uid);

      final base = {
        'uid': uid,
        'email': _email.text.trim(),
        'takmaAd': _nick.text.trim(),
        'requestedRole': requestedRole,
        'role': role,
        'status': status,
        'location': location,
        'agreements': {
          'uyelik_sozlesmesi': true,
          'acik_riza': true,
        },
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await userRef.set(base, SetOptions(merge: true));
      await regRef.set(base, SetOptions(merge: true));

      // 🔹 4. Mock servis güncelle
      final basvuru = Basvuru(
        uid: uid,
        takmaAd: _nick.text,
        telefon: '',
        requestedRole: role,
        location: location,
        okul: '',
        status: status,
        createdAt: DateTime.now(),
      );
      OnayServisi().kayitEkleVeyaGuncelle(basvuru);
      await OnayServisi().kaydaOnaylayiciAtaVeyaOtoOnayla(
        registrationUid: uid,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isFirstUser
              ? 'İlk kullanıcı olarak Baş Admin oldunuz.'
              : 'Kaydınız başarıyla oluşturuldu.'),
        ),
      );

      Navigator.pushReplacementNamed(context, RouteNames.sozlesmeKabul,
          arguments: uid);
    } catch (e) {
      setState(() => _hata = e.toString());
    } finally {
      setState(() => _islem = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 10);
    return Scaffold(
      appBar: AppBar(title: const Text('Kayıt Ol (Email)')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Card(
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12))),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    if (_hata != null)
                      Text(_hata!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center),
                    const SizedBox(height: 8),

                    TextFormField(
                      controller: _nick,
                      decoration:
                          const InputDecoration(labelText: 'Takma Ad (nickname)'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Gerekli' : null,
                    ),
                    gap,
                    TextFormField(
                      controller: _email,
                      decoration:
                          const InputDecoration(labelText: 'E-posta adresi'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) =>
                          (v == null || !v.contains('@')) ? 'Geçersiz e-posta' : null,
                    ),
                    gap,
                    TextFormField(
                      controller: _sifre,
                      decoration: const InputDecoration(labelText: 'Şifre'),
                      obscureText: true,
                      validator: (v) =>
                          (v == null || v.length < 6) ? 'Min 6 karakter' : null,
                    ),
                    gap,
                    TextFormField(
                      controller: _sifre2,
                      decoration:
                          const InputDecoration(labelText: 'Şifre (tekrar)'),
                      obscureText: true,
                      validator: (v) =>
                          (v == null || v.length < 6) ? 'Min 6 karakter' : null,
                    ),

                    const SizedBox(height: 20),
                    const Divider(),
                    const _GrupBaslik('Rol Seçimi'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _roller.map((rol) {
                        final secili = _seciliRol == rol;
                        return ChoiceChip(
                          label: Text(rol),
                          selected: secili,
                          onSelected: (_) =>
                              setState(() => _seciliRol = rol),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),
                    const Divider(),
                    const _GrupBaslik('Sözleşmeler'),
                    CheckboxListTile(
                      value: _uyelikKabul,
                      onChanged: (v) => setState(() => _uyelikKabul = v ?? false),
                      title: const Text('Kullanıcı Sözleşmesini kabul ediyorum.'),
                    ),
                    CheckboxListTile(
                      value: _acikRizaKabul,
                      onChanged: (v) => setState(() => _acikRizaKabul = v ?? false),
                      title:
                          const Text('Açık Rıza Metnini kabul ediyorum.'),
                    ),
                    CheckboxListTile(
                      value: _bilgiOnayi,
                      onChanged: (v) => setState(() => _bilgiOnayi = v ?? false),
                      title:
                          const Text('Bilgilerimin doğruluğunu onaylıyorum.'),
                    ),
                    const SizedBox(height: 16),

                    ElevatedButton(
                      onPressed: _islem ? null : _kayit,
                      child: _islem
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Kayıt Ol'),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
      ),
    );
  }
}
