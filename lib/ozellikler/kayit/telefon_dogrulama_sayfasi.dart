// lib/ozellikler/kayit/telefon_dogrulama_sayfasi.dart
// (Değiştirildi: artık e-posta ile kayıt yapar)
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EmailRegisterSayfasi extends StatefulWidget {
  static const route = '/email_register'; // geçici route string, router'da eşleştir
  const EmailRegisterSayfasi({super.key});

  @override
  State<EmailRegisterSayfasi> createState() => _EmailRegisterSayfasiState();
}

class _EmailRegisterSayfasiState extends State<EmailRegisterSayfasi> {
  final _formKey = GlobalKey<FormState>();

  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _pass2Ctrl = TextEditingController();
  final _nickCtrl = TextEditingController();
  final _fullNameCtrl = TextEditingController();

  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _pass2Ctrl.dispose();
    _nickCtrl.dispose();
    _fullNameCtrl.dispose();
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

  String? _emailValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Gerekli';
    final re = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!re.hasMatch(v.trim())) return 'Geçerli bir e-posta girin';
    return null;
  }

  String? _passValidator(String? v) {
    if (v == null || v.isEmpty) return 'Gerekli';
    if (v.length < 6) return 'En az 6 karakter';
    return null;
  }

  Future<void> _kayitOl() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    final pass2 = _pass2Ctrl.text;
    final nick = _temizTakmaAd(_nickCtrl.text);
    final fullName = _fullNameCtrl.text.trim();

    if (pass != pass2) {
      setState(() => _error = 'Şifreler uyuşmuyor');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 1) Firebase Auth ile e-posta kaydı
      final auth = FirebaseAuth.instance;
      final userCred = await auth.createUserWithEmailAndPassword(
        email: email,
        password: pass,
      );

      final user = userCred.user;
      if (user == null) throw Exception('Kullanıcı oluşturulamadı.');

      // İsteğe bağlı: displayName güncelle (hata verirse pas geç)
      try {
        await user.updateDisplayName(fullName.isNotEmpty ? fullName : nick);
      } catch (_) {}

      // (İsteğe bağlı) e-posta doğrulama gönder
      try {
        if (!user.emailVerified) {
          await user.sendEmailVerification();
        }
      } catch (_) {}

      // 2) Firestore'a kullanıcı belgesi yaz (merge)
      final firestore = FirebaseFirestore.instance;
      final docRef = firestore.collection('kullanicilar').doc(user.uid);

      final now = DateTime.now().toUtc().toIso8601String();
      await docRef.set({
        'uid': user.uid,
        'nick': nick,
        'fullName': fullName,
        'email': email,
        'telefon': null,
        'sozlesmeKabul': false, // henüz kabul etmedi
        'kayıtAsamalari': {
          'email': true,
          'rol': false,
          'ilgi': false,
          'legal': false,
        },
        'createdAt': now,
      }, SetOptions(merge: true));

      // 3) Navigasyon: rol seçim / ilgi akışına gönder
      // Router'ınız RouteNames kullanıyorsa oraya yönlendir; burada doğrudan route string kullanıyorum.
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/rol_sec', arguments: {'uid': user.uid});

    } on FirebaseAuthException catch (e) {
      String message = 'Kayıt başarısız: ${e.code}';
      if (e.code == 'email-already-in-use') {
        message = 'Bu e-posta zaten kullanılıyor.';
      } else if (e.code == 'invalid-email') {
        message = 'Geçersiz e-posta adresi.';
      } else if (e.code == 'weak-password') {
        message = 'Şifre çok zayıf.';
      } else if (e.code == 'operation-not-allowed') {
        message = 'E-posta ile kayıt izni kapalı. Firebase Console kontrol et.';
      }
      setState(() => _error = message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('E-posta ile Kayıt'),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    const SizedBox(height: 8),
                    const Center(child: FlutterLogo(size: 56)), // Placeholder logo
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _nickCtrl,
                      decoration: const InputDecoration(labelText: 'Takma ad (kullanıcı adı)'),
                      textInputAction: TextInputAction.next,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Gerekli' : null,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _fullNameCtrl,
                      decoration: const InputDecoration(labelText: 'Ad Soyad'),
                      textInputAction: TextInputAction.next,
                      validator: (v) => (v == null || v.trim().length < 3) ? 'Geçerli bir ad soyad girin' : null,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _emailCtrl,
                      decoration: const InputDecoration(labelText: 'E-posta'),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: _emailValidator,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _passCtrl,
                      decoration: const InputDecoration(labelText: 'Şifre (en az 6 karakter)'),
                      obscureText: true,
                      textInputAction: TextInputAction.next,
                      validator: _passValidator,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _pass2Ctrl,
                      decoration: const InputDecoration(labelText: 'Şifre (tekrar)'),
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Gerekli';
                        if (v != _passCtrl.text) return 'Şifreler uyuşmuyor';
                        return null;
                      },
                      onFieldSubmitted: (_) => _kayitOl(),
                    ),
                    const SizedBox(height: 16),

                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(_error!, style: const TextStyle(color: Colors.red)),
                      ),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _kayitOl,
                        child: _isLoading
                            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Kayıt Ol ve Devam Et'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // geri (eğer gerekiyorsa)
                      },
                      child: const Text('Geri'),
                    )
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
