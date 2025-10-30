import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
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

  // Asset dosyasını açar
  Future<void> _acAssetTR(String baslik, String dosyaAdi) async {
    final path = 'assets/hukuk/tr/$dosyaAdi';
    final icerik = await rootBundle.loadString(path);
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(baslik),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Text(icerik),
            ),
          ),
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
          .set({
        'sozlesme': {
          'kullanim': true,
          'kvkk': true,
          'acikRiza': true,
          'onayZamani': FieldValue.serverTimestamp(),
          'kaynak': 'assets/hukuk/tr/',
        },
        'profilDurumu': 'tamamlandi',
      }, SetOptions(merge: true));

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
              leading: const Icon(Icons.description),
              trailing: const Icon(Icons.open_in_new),
              onTap: () => _acAssetTR('Kullanım Şartları', 'kullanim_sartlari.txt'),
            ),
            ListTile(
              title: const Text('Aydınlatma Metni (KVKK)'),
              leading: const Icon(Icons.shield_outlined),
              trailing: const Icon(Icons.open_in_new),
              onTap: () => _acAssetTR('Aydınlatma Metni', 'aydinlatma_metni.txt'),
            ),
            ListTile(
              title: const Text('Açık Rıza Metni'),
              leading: const Icon(Icons.privacy_tip_outlined),
              trailing: const Icon(Icons.open_in_new),
              onTap: () => _acAssetTR('Açık Rıza Metni', 'acik_riza.txt'),
            ),
            const Divider(),
            CheckboxListTile(
              value: _kabul,
              onChanged: (v) => setState(() => _kabul = v ?? false),
              title: const Text(
                'Yukarıdaki tüm metinleri okudum ve kabul ediyorum.',
              ),
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
