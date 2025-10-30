import 'package:flutter/material.dart';
import '../../hizmetler/auth_servisi.dart';

class AnaSayfa extends StatelessWidget {
  const AnaSayfa({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EduPlas'),
        actions: [
          IconButton(
            onPressed: () async {
              await AuthServisi().cikisYap();
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Çıkış',
          )
        ],
      ),
      body: const Center(
        child: Text('Giriş başarılı! (Sprint-1 Ana Sayfa Yer Tutucu)'),
      ),
    );
  }
}


