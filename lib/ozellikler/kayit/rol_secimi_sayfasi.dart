// lib/ozellikler/kayit/rol_secimi_sayfasi.dart
import 'package:flutter/material.dart';
import 'package:eduplas/router/route_names.dart';

class RolSecimiSayfasi extends StatefulWidget {
  // const + RouteNames.olmaz → string literal
  static const route = '/kayit/rol_sec';

  const RolSecimiSayfasi({super.key});

  @override
  State<RolSecimiSayfasi> createState() => _RolSecimiSayfasiState();
}

class _RolSecimiSayfasiState extends State<RolSecimiSayfasi> {
  static const _roller = <String>[
    'Öğrenci',
    'Öğretmen',
    'Sınıf Başkanı',
    'Koordinatör',
    'İlçe Admin',
    'İl Admin',
    'Baş Admin',
    'Destekçi',
    'İşyeri',
  ];

  String? _seciliRol;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rol Seç'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('EduPlas ekosisteminde hangi rolde olacaksın?'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _roller.map((rol) {
                final secili = _seciliRol == rol;
                return ChoiceChip(
                  label: Text(rol),
                  selected: secili,
                  onSelected: (_) {
                    setState(() => _seciliRol = rol);
                  },
                );
              }).toList(),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _seciliRol == null
                    ? null
                    : () {
                        // rol seçtikten sonra ilgi sayfasına
                        Navigator.pushReplacementNamed(
                          context,
                          RouteNames.ilgiSec,
                          arguments: {
                            'role': _seciliRol,
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
