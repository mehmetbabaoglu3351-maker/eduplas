// lib/ozellikler/kayit/ilgi_secimi_sayfasi.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:eduplas/router/route_names.dart';

class IlgiSecimiSayfasi extends StatefulWidget {
  static const route = RouteNames.ilgiSec;
  const IlgiSecimiSayfasi({super.key});

  @override
  State<IlgiSecimiSayfasi> createState() => _IlgiSecimiSayfasiState();
}

class _IlgiSecimiSayfasiState extends State<IlgiSecimiSayfasi> {
  // 👇 Daha kapsayıcı, EduPlas senaryosuna uygun liste
  final List<String> _tumIlgiler = const [
    // Eğitim / Bilim
    'Matematik',
    'Fen & Teknoloji',
    'Yabancı Dil',
    // Sanat / Yaratıcılık
    'Müzik',
    'Şiir & Edebiyat',
    'Tiyatro & Sahne',
    'Resim & Tasarım',
    // Dijital / Gelecek
    'Kodlama & Yapay Zekâ',
    'Robotik & Maker',
    // Sosyal / Yaşam
    'Spor & Sağlık',
    'Kişisel Gelişim',
    'Sosyal Sorumluluk',
    // Ekonomi / İş
    'Ekonomi & Finans',
    'Girişimcilik',
  ];

  final Set<String> _secili = {};
  bool _kaydediyor = false;
  String? _hata;

  Future<void> _devamEt() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _hata = 'Oturum bulunamadı.');
      return;
    }

    setState(() {
      _kaydediyor = true;
      _hata = null;
    });

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(
        {
          'ilgiler': _secili.toList(),
          'ilgiKayitZamani': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(RouteNames.sozlesmeKabul);
    } catch (e) {
      setState(() => _hata = e.toString());
    } finally {
      if (mounted) setState(() => _kaydediyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('İlgi Alanlarını Seç')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Seni ilgilendiren alanları seç. İstersen sonra profilden değiştirebilirsin.',
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: _tumIlgiler.length,
                itemBuilder: (context, index) {
                  final ad = _tumIlgiler[index];
                  final tikli = _secili.contains(ad);
                  return CheckboxListTile(
                    value: tikli,
                    title: Text(ad),
                    onChanged: (v) {
                      setState(() {
                        if (v == true) {
                          _secili.add(ad);
                        } else {
                          _secili.remove(ad);
                        }
                      });
                    },
                  );
                },
              ),
            ),
            if (_hata != null)
              Text(_hata!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _kaydediyor ? null : _devamEt,
                child: _kaydediyor
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Devam'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
