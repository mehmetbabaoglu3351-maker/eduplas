// lib/ozellikler/kayit/telefon_dogrulama_sayfasi.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eduplas/router/route_names.dart';

class TelefonDogrulamaSayfasi extends StatefulWidget {
  static const route = RouteNames.otp;
  const TelefonDogrulamaSayfasi({super.key});

  @override
  State<TelefonDogrulamaSayfasi> createState() =>
      _TelefonDogrulamaSayfasiState();
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

  Future<void> _onayla() async {
    final kod = _kodController.text.trim();
    if (kod.isEmpty) return;

    // Girişten gelen veriler
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final nick = (args?['nick'] ?? 'kullanici').toString();
    final adSoyad = (args?['adSoyad'] ?? '').toString();
    final tel = (args?['tel'] ?? '').toString();
    final pass = (args?['pass'] ?? 'Eduplas123!').toString();

    // senin aldığın domain
    final email = '${nick.toLowerCase()}@eduplas.club';

    setState(() {
      _islem = true;
      _hata = null;
    });

    try {
      // 1) AUTH OLUŞTUR
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: pass,
      );

      // 2) DISPLAY NAME
      await cred.user?.updateDisplayName(adSoyad);

      // 3) 🔴 FIRESTORE’A YAZ
      // koleksiyon adını istersen 'kullanicilar' yapabilirsin
      await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .set({
        'uid': cred.user!.uid,
        'nick': nick,
        'adSoyad': adSoyad,
        'tel': tel,
        'email': email,
        'rol': null,              // rol_seciminden sonra güncelleriz
        'ilgiler': <String>[],    // ilgi_seciminden sonra güncelleriz
        'createdAt': FieldValue.serverTimestamp(),
        'kaynak': 'otp-akisi-v1',
      });

      if (!mounted) return;
      // 4) Akışa devam → ROL SEÇ
      Navigator.of(context)
          .pushReplacementNamed(RouteNames.rolSec, arguments: args);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        try {
          final signInCred =
              await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: email,
            password: pass,
          );

          // Kullanıcı daha önce oluşmuş ama Firestore'da olmayabilir → garantiye al
          await FirebaseFirestore.instance
              .collection('users')
              .doc(signInCred.user!.uid)
              .set({
            'uid': signInCred.user!.uid,
            'nick': nick,
            'adSoyad': adSoyad,
            'tel': tel,
            'email': email,
            'rol': null,
            'ilgiler': <String>[],
            'createdAt': FieldValue.serverTimestamp(),
            'kaynak': 'otp-akisi-v1-signin',
          }, SetOptions(merge: true));

          if (!mounted) return;
          Navigator.of(context)
              .pushReplacementNamed(RouteNames.rolSec, arguments: args);
        } on FirebaseAuthException catch (e2) {
          setState(() => _hata = e2.message ?? 'Giriş yapılamadı.');
        }
      } else if (e.code == 'operation-not-allowed') {
        setState(() => _hata = 'Firebase\'de Email/Şifre oturumu aktif değil.');
      } else {
        setState(() => _hata = e.message ?? 'Bilinmeyen hata.');
      }
    } catch (e) {
      setState(() => _hata = e.toString());
    } finally {
      if (mounted) setState(() => _islem = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Telefon Doğrulama')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Telefonuna gelen doğrulama kodunu gir. (mock)'),
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

