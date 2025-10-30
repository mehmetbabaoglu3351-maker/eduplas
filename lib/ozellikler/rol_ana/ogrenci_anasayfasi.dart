// lib/ozellikler/rol_ana/ogrenci_anasayfasi.dart
import 'package:flutter/material.dart';
import 'package:eduplas/ozellikler/rol_ana/onaylarim_butonu.dart';

class OgrenciAnasayfasi extends StatelessWidget {
  static const route = '/ogrenci-anasayfasi';

  const OgrenciAnasayfasi({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Öğrenci Ana Sayfası')),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            OnaylarimButonu(role: 'Öğrenci'),
            SizedBox(height: 16),
            Text('Hoş geldin!'),
          ],
        ),
      ),
    );
  }
}


