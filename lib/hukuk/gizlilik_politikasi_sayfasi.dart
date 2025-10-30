// lib/hukuk/gizlilik_politikasi_sayfasi.dart
import 'package:flutter/material.dart';

class GizlilikPolitikasiSayfasi extends StatelessWidget {
  static const route = '/hukuk/gizlilik';

  const GizlilikPolitikasiSayfasi({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gizlilik Politikası'),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Text(
          'Bu politika, EduPlas\'ın topladığı verileri nasıl sakladığını, '
          'hangi taraflarla paylaştığını ve güvenliğini nasıl sağladığını açıklar. '
          'Sürüm: v1.0',
        ),
      ),
    );
  }
}
