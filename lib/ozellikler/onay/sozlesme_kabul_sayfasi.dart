// lib/ozellikler/onay/sozlesme_kabul_sayfasi.dart
// EduPlas – Tek Sözleşme Onay Ekranı (SADE / WEB YOK)
// - Metin sadece uygulama içindeki asset'ten okunur
// - Kullanıcı "okudum, kabul ediyorum" demeden geçemez
// - Kabulde Firestore -> users/{uid} içine sozlesmeKabul: true yazılır

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:eduplas/router/route_names.dart';

class SozlesmeKabulSayfasi extends StatefulWidget {
  static const route = RouteNames.sozlesmeKabul;

  const SozlesmeKabulSayfasi({super.key});

  @override
  State<SozlesmeKabulSayfasi> createState() => _SozlesmeKabulSayfasiState();
}

class _SozlesmeKabulSayfasiState extends State<SozlesmeKabulSayfasi> {
  // Tek sözleşme dosyası (TR)
  // pubspec.yaml:
  // assets:
  //   - assets/hukuk/eduplas_sozlesme_tr.txt
  static const String _assetYolu = 'assets/hukuk/eduplas_sozlesme_tr.txt';

  String _metin = '';
  bool _yukleniyor = true;
  bool _kabul = false;
  bool _islemde = false;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    try {
      final icerik = await rootBundle.loadString(_assetYolu);
      if (!mounted) return;
      setState(() {
        _metin = icerik;
        _yukleniyor = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _metin = '''
EDUPLAS TEK KULLANICI SÖZLEŞMESİ

Uygulama içinde gösterilecek sözleşme metni bulunamadı.
Lütfen yöneticinizden "$_assetYolu" dosyasını eklemesini isteyin.
''';
        _yukleniyor = false;
      });
    }
  }

  Future<void> _kaydet() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kullanıcı oturumu bulunamadı.')),
      );
      return;
    }
    setState(() => _islemde = true);

    final db = FirebaseFirestore.instance;
    final ref = db.collection('users').doc(user.uid);

    await ref.set({
      'sozlesmeKabul': true,
      'sozlesmeSurum': '1.0',
      'sozlesmeTarih': DateTime.now().toIso8601String(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(RouteNames.user);
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sözleşme Onayı'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Logo / başlık alanı (senin standart)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EduPlas',
                    style: tema.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Öğren kazan, öğret kazandır.',
                    style: tema.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Lütfen aşağıdaki sözleşmeyi okuyup onaylayın.',
                    style: tema.textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _yukleniyor
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _metin,
                        style: const TextStyle(fontSize: 14, height: 1.4),
                      ),
                    ),
            ),
            CheckboxListTile(
              value: _kabul,
              onChanged: (v) => setState(() => _kabul = v ?? false),
              title: const Text('Tüm şartları okudum ve kabul ediyorum.'),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed:
                      (!_kabul || _islemde || _yukleniyor) ? null : _kaydet,
                  icon: _islemde
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: const Text('Kaydet ve devam et'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
