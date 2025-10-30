// lib/ozellikler/kayit/ilgi_secimi_sayfasi.dart
import 'package:flutter/material.dart';
import 'package:eduplas/router/route_names.dart';

class IlgiSecimiSayfasi extends StatefulWidget {
  static const route = RouteNames.ilgiSec;
  const IlgiSecimiSayfasi({super.key});

  @override
  State<IlgiSecimiSayfasi> createState() => _IlgiSecimiSayfasiState();
}

class _IlgiSecimiSayfasiState extends State<IlgiSecimiSayfasi> {
  final List<String> _tumIlgiler = const [
    'Matematik',
    'Fen',
    'Kodlama',
    'Yapay Zeka',
    'Müzik',
    'Şiir',
    'Yabancı Dil',
    'Robotik',
  ];

  final Set<String> _secili = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('İlgi Alanı Seç')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _tumIlgiler.length,
                itemBuilder: (context, index) {
                  final ad = _tumIlgiler[index];
                  final tikli = _secili.contains(ad);
                  return CheckboxListTile(
                    value: tikli,
                    title: Text(ad),
                    onChanged: (v) {
                      setState(() {
                        if (v == true) {
                          _secili.add(ad);
                        } else {
                          _secili.remove(ad);
                        }
                      });
                    },
                  );
                },
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // ilgi seçtikten sonra → sözleşme
                  Navigator.of(context)
                      .pushReplacementNamed(RouteNames.sozlesmeKabul);
                },
                child: const Text('Devam'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
