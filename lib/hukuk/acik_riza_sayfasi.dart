// lib/hukuk/acik_riza_sayfasi.dart
import 'package:flutter/material.dart';

class AcikRizaSayfasi extends StatelessWidget {
  static const route = '/hukuk/acik-riza';

  const AcikRizaSayfasi({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Açık Rıza Beyanı'),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Text(
          'Kişisel verilerinizin işlenmesi için açık rızanız talep edilmektedir. '
          'Bu metni onaylamanız bazı özelliklerin kullanılabilmesi için zorunludur. '
          'Sürüm: v1.0',
        ),
      ),
    );
  }
}
