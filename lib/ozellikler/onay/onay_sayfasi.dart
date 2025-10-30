// lib/ozellikler/onay/onay_sayfasi.dart
import 'package:flutter/material.dart';
import 'package:eduplas/router/route_names.dart';

class OnaySayfasi extends StatelessWidget {
  // const + RouteNames.onay => hata → string literal
  static const route = '/onay';

  const OnaySayfasi({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Onaylarım')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ListTile(
            leading: Icon(Icons.description),
            title: Text('Kullanıcı Sözleşmesi'),
            subtitle: Text('Kabul edildi'),
          ),
          ListTile(
            leading: Icon(Icons.privacy_tip_outlined),
            title: Text('Gizlilik Politikası'),
            subtitle: Text('Gösterildi'),
          ),
          ListTile(
            leading: Icon(Icons.medical_information_outlined),
            title: Text('Aydınlatma Metni'),
            subtitle: Text('Gösterildi'),
          ),
        ],
      ),
    );
  }
}
