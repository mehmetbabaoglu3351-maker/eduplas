// lib/ozellikler/kapigecit/kapigecit.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../hizmetler/auth_servisi.dart';
import '../giris/giris_sayfasi.dart';
import '../giris/ana_sayfa.dart';

class KapiGecit extends StatelessWidget {
  const KapiGecit({super.key});

  @override
  Widget build(BuildContext context) {
    final servis = AuthServisi();
    return StreamBuilder<User?>(
      stream: servis.durumAkisi(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasData) {
          return const AnaSayfa();
        }
        return const GirisSayfasi();
      },
    );
  }
}


