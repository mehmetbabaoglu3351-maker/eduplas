// lib/ozellikler/onay/sozlesme_kabul_sayfasi.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:eduplas/router/route_names.dart';

class SozlesmeKabulSayfasi extends StatefulWidget {
  const SozlesmeKabulSayfasi({super.key});

  @override
  State<SozlesmeKabulSayfasi> createState() => _SozlesmeKabulSayfasiState();
}

class _SozlesmeKabulSayfasiState extends State<SozlesmeKabulSayfasi> {
  bool _kabul = false;
  bool _kaydediyor = false;
  String? _hata;

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

  Future<void> _tamamla() async {
    if (!_kabul) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _hata = 'Oturum bulunamadı.');
      return;
    }

    setState(() {
      _kaydediyor = true;
      _hata = null;
    });

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(
        {
          'sozlesme': {
            'kullanim': true,
            'kvkk': true,
            'acikRiza': true,
            'onayZamani': FieldValue.serverTimestamp(),
          },
          'profilDurumu': 'tamamlandi',
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(RouteNames.user);
    } catch (e) {
      setState(() => _hata = e.toString());
    } finally {
      if (mounted) setState(() => _kaydediyor = false);
    }
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
              onTap: () => _ac('Kullanım Şartları',
                  'Buraya kullanım şartlarının metni gelecek...'),
            ),
            ListTile(
              title: const Text('Aydınlatma Metni'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _ac(
                  'Aydınlatma Metni', 'Buraya KVKK / aydınlatma metni gelecek...'),
            ),
            ListTile(
              title: const Text('Açık Rıza Metni'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _ac(
                  'Açık Rıza Metni', 'Buraya açık rıza metni gelecek...'),
            ),
            const Divider(),
            CheckboxListTile(
              value: _kabul,
              onChanged: (v) => setState(() => _kabul = v ?? false),
              title: const Text(
                  'Yukarıdaki tüm metinleri okudum ve kabul ediyorum.'),
            ),
            if (_hata != null)
              Text(_hata!, style: const TextStyle(color: Colors.red)),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _kaydediyor ? null : _tamamla,
                child: _kaydediyor
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Kaydı tamamla'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
