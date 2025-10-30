// lib/hukuk/uyelik_sozlesmesi_sayfasi.dart
import 'package:flutter/material.dart';

class UyelikSozlesmesiSayfasi extends StatelessWidget {
  static const route = '/hukuk/uyelik';

  const UyelikSozlesmesiSayfasi({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Üyelik Sözleşmesi'),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Text(
          'Burada EduPlas sistemini kullanmanın genel şartları yer alır. '
          'Kullanıcı; kayıt olarak bu şartları kabul etmiş sayılır. '
          'Bu metin v1.0 sürümündedir.',
        ),
      ),
    );
  }
}
