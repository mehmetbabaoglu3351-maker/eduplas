// lib/ozellikler/kayit/telefon_dogrulama_sayfasi.dart
//
// EduPlas A1 – Düzeltilmiş OTP
// - TR alan adları eklendi: adSoyad, telefon, e-posta, Nick
// - Boş fullName geldiyse nick’ten üretir
// - Başarılı olunca ZORLA rol seçimine gider
// - 3 modu destekler: login / register / recovery
// - DEV kodları: 000000, 111111, 123456

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eduplas/router/route_names.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:eduplas/cekirdek/arayuz/app_logo.dart';

class TelefonDogrulamaSayfasi extends StatefulWidget {
  static const route = RouteNames.otp;
  const TelefonDogrulamaSayfasi({super.key});

  @override
  State<TelefonDogrulamaSayfasi> createState() => _TelefonDogrulamaSayfasiState();
}

class _TelefonDogrulamaSayfasiState extends State<TelefonDogrulamaSayfasi> {
  final _kodController = TextEditingController();
  bool _islem = false;
  String? _hata;

  @override
  void dispose() {
    _kodController.dispose();
    super.dispose();
  }

  bool _gecerliDevKod(String s) {
    return s == '000000' || s == '111111' || s == '123456';
  }

  Future<void> _onayla() async {
    final girilenKod = _kodController.text.trim();
    if (girilenKod.isEmpty) return;

    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final mode = (args?['mode'] ?? 'register').toString(); // login | register | recovery

    // Giriş ekranından gelen isimler
    final rawNick = (args?['nick'] ?? 'kullanici').toString();
    final rawFullName = (args?['fullName'] ?? '').toString();
    final rawPhone = (args?['phone'] ?? '').toString();
    final password = (args?['password'] ?? 'Eduplas123!').toString();

    // Boş adSoyad geldiyse nick’ten üret
    final fullName = rawFullName.isEmpty ? rawNick : rawFullName;

    // e-posta formatı: nick@eduplas.club
    final email = '${rawNick.toLowerCase()}@eduplas.club';

    if (!_gecerliDevKod(girilenKod)) {
      setState(() {
        _hata = 'Kod geçersiz veya süresi doldu.';
      });
      return;
    }

    setState(() {
      _islem = true;
      _hata = null;
    });

    try {
      if (mode == 'login') {
        // 1) GİRİŞ
        final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        await _kullaniciDocYaz(
          uid: cred.user!.uid,
          nick: rawNick,
          fullName: fullName,
          phone: rawPhone,
          email: email,
          kaynak: 'a1-login',
        );

        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed(RouteNames.rolSec, arguments: args);
        return;
      }

      if (mode == 'recovery') {
        // 2) KURTARMA
        User? kullanici;
        try {
          final signIn = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
          kullanici = signIn.user;
        } on FirebaseAuthException {
          final newUser = await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
          kullanici = newUser.user;
        }

        if (kullanici != null) {
          await kullanici.updateDisplayName(fullName);
        }

        await _kullaniciDocYaz(
          uid: kullanici!.uid,
          nick: rawNick,
          fullName: fullName,
          phone: rawPhone,
          email: email,
          kaynak: 'a1-recovery',
        );

        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed(RouteNames.rolSec, arguments: args);
        return;
      }

      // 3) KAYIT (varsayılan)
      try {
        final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        await cred.user?.updateDisplayName(fullName);

        await _kullaniciDocYaz(
          uid: cred.user!.uid,
          nick: rawNick,
          fullName: fullName,
          phone: rawPhone,
          email: email,
          kaynak: 'a1-kayit',
        );

        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed(RouteNames.rolSec, arguments: args);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          // varsa girişe çevir
          final signInCred = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: email,
            password: password,
          );

          await _kullaniciDocYaz(
            uid: signInCred.user!.uid,
            nick: rawNick,
            fullName: fullName,
            phone: rawPhone,
            email: email,
            kaynak: 'a1-kayit-existing',
          );

          if (!mounted) return;
          Navigator.of(context).pushReplacementNamed(RouteNames.rolSec, arguments: args);
        } else {
          setState(() => _hata = e.message);
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _hata = e.message);
    } catch (e) {
      setState(() => _hata = e.toString());
    } finally {
      if (mounted) setState(() => _islem = false);
    }
  }

  /// Firestore’a hem TR hem de eski alan adlarıyla yazar.
  Future<void> _kullaniciDocYaz({
    required String uid,
    required String nick,
    required String fullName,
    required String phone,
    required String email,
    required String kaynak,
  }) async {
    final users = FirebaseFirestore.instance.collection('users').doc(uid);

    await users.set({
      'uid': uid,
      // Senin kayıtta görünen isimlere uyduk:
      'Nick': nick,            // 👈 TR projendeki hali
      'nick': nick,            // 👈 yeni akış
      'adSoyad': fullName,     // 👈 Firestore’da gördüğün boş alan
      'fullName': fullName,    // 👈 yeni akış
      'telefon': phone,        // 👈 Firestore’da gördüğün boş alan
      'phone': phone,          // 👈 yeni akış
      'e-posta': email,        // 👈 senin alan ismin
      'email': email,          // 👈 yeni akış
      'rol': null,
      'ilgiler': <String>[],
      'sozlesmeKabul': true,   // 👈 senin kayıtta zaten true gelmiş
      'sozlesmeSurum': '1.0',
      'sozlesmeTarih': DateTime.now().toIso8601String(),
      'kaynak': kaynak,
      'guncellendi': FieldValue.serverTimestamp(),
      'olusturuldu': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final mode = (args?['mode'] ?? 'register').toString();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          switch (mode) {
            'login' => 'Telefon Doğrulama (Giriş)',
            'recovery' => 'Hesap Kurtarma Doğrulaması',
            _ => 'Telefon Doğrulama',
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const AppLogo(daire: true, compactHint: true),
            const SizedBox(height: 4),
            Text(
              'EduPlas',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: const Color(0xFF00BFA5),
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Öğren, kazan; Öğret, kazandır.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.black54,
                  ),
            ),
            const SizedBox(height: 20),
            Text(
              switch (mode) {
                'login' => 'Giriş işlemini tamamlamak için doğrulama kodunu gir.',
                'recovery' => 'Hesabını kurtarmak için doğrulama kodunu gir.',
                _ => 'Telefonuna gelen doğrulama kodunu gir.',
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _kodController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Doğrulama Kodu',
                hintText: '000000',
              ),
            ),
            const SizedBox(height: 12),
            if (_hata != null)
              Text(
                _hata!,
                style: const TextStyle(color: Colors.red),
              ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _islem ? null : _onayla,
                child: _islem
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Onayla'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
