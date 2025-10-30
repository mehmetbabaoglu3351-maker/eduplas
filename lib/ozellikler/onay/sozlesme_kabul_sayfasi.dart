// lib/ozellikler/onay/sozlesme_kabul_sayfasi.dart
import 'package:flutter/material.dart';
import 'package:eduplas/router/route_names.dart';

class SozlesmeKabulSayfasi extends StatefulWidget {
  const SozlesmeKabulSayfasi({super.key});

  @override
  State<SozlesmeKabulSayfasi> createState() => _SozlesmeKabulSayfasiState();
}

class _SozlesmeKabulSayfasiState extends State<SozlesmeKabulSayfasi> {
  bool _kabul = false;

  void _ac(String title, String icerik) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(child: Text(icerik)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Kapat'),
            ),
          ],
        );
      },
    );
  }

  void _tamamla() {
    if (!_kabul) return;
    Navigator.of(context).pushReplacementNamed(RouteNames.user);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sözleşmeler')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              title: const Text('Kullanım Şartları'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                _ac('Kullanım Şartları', 'Buraya kullanım şartlarının metni gelecek...');
              },
            ),
            ListTile(
              title: const Text('Aydınlatma Metni'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                _ac('Aydınlatma Metni', 'Buraya KVKK / aydınlatma metni gelecek...');
              },
            ),
            ListTile(
              title: const Text('Açık Rıza Metni'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                _ac('Açık Rıza Metni', 'Buraya açık rıza metni gelecek...');
              },
            ),
            const Divider(),
            CheckboxListTile(
              value: _kabul,
              onChanged: (v) => setState(() => _kabul = v ?? false),
              title: const Text(
                'Yukarıdaki tüm metinleri okudum ve kabul ediyorum.',
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _kabul ? _tamamla : null,
                child: const Text('Kaydı tamamla'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
