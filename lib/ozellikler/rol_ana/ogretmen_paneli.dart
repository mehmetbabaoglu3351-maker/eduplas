// lib/ozellikler/rol_ana/ogretmen_paneli.dart
import 'package:flutter/material.dart';
import 'package:eduplas/ozellikler/rol_ana/onaylarim_butonu.dart';

class OgretmenPaneli extends StatelessWidget {
  static const route = '/ogretmen-paneli';

  const OgretmenPaneli({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Öğretmen Paneli')),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            OnaylarimButonu(role: ''),
            SizedBox(height: 16),
            Text('Ders ve onay yönetimine hazır!'),
          ],
        ),
      ),
    );
  }
}


