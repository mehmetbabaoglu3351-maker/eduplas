// lib/hukuk/aydinlatma_sayfasi.dart
import 'package:flutter/material.dart';

class AydinlatmaSayfasi extends StatelessWidget {
  static const route = '/hukuk/aydinlatma';

  const AydinlatmaSayfasi({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aydınlatma Metni (KVKK)'),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Text(
          'EduPlas, kişisel verilerinizi 6698 sayılı KVKK kapsamında işler. '
          'Hangi verilerin hangi amaçlarla işlendiği bu metinde açıklanmıştır. '
          'Sürüm: v1.0',
        ),
      ),
    );
  }
}
