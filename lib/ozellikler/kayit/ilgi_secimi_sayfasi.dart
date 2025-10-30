// lib/ozellikler/kayit/ilgi_secimi_sayfasi.dart
import 'package:flutter/material.dart';
import 'package:eduplas/router/route_names.dart';

class IlgiSecimiSayfasi extends StatefulWidget {
  // DİKKAT: burada const yerine sabit string kullanıyoruz
  static const route = '/kayit/ilgi_sec';

  const IlgiSecimiSayfasi({super.key});

  @override
  State<IlgiSecimiSayfasi> createState() => _IlgiSecimiSayfasiState();
}

class _IlgiSecimiSayfasiState extends State<IlgiSecimiSayfasi> {
  static const _ilgiSecenekleri = <String>[
    'Matematik',
    'Fen',
    'Kodlama',
    'Robotik',
    'Yapay Zekâ',
    'Yabancı Dil',
    'Edebiyat',
    'Tarih',
    'Coğrafya',
    'Sanat',
    'Müzik',
    'Spor',
    'Satranç',
    'Girişimcilik',
    'Psikoloji',
  ];

  final Set<String> _secili = <String>{};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İlgi Alanlarını Seç'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Seni en iyi anlatan alanları seç (opsiyonel):'),
            const SizedBox(height: 12),
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _ilgiSecenekleri.map((e) {
                  final secili = _secili.contains(e);
                  return FilterChip(
                    label: Text(e),
                    selected: secili,
                    onSelected: (_) {
                      setState(() {
                        if (secili) {
                          _secili.remove(e);
                        } else {
                          _secili.add(e);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // buradan hukuk / sözleşmeye geç
                  Navigator.pushReplacementNamed(
                    context,
                    RouteNames.sozlesmeKabul,
                    arguments: {
                      'ilgiler': _secili.toList(),
                    },
                  );
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
