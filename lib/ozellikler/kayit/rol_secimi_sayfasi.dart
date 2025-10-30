// lib/ozellikler/kayit/rol_secimi_sayfasi.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:eduplas/router/route_names.dart';

class RolSecimiSayfasi extends StatefulWidget {
  static const route = RouteNames.rolSec;
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
  bool _kaydediyor = false;
  String? _hata;

  Future<void> _devamEt() async {
    if (_seciliRol == null) return;

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
          'rol': _seciliRol,
          'rolKayitZamani': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(RouteNames.ilgiSec);
    } catch (e) {
      setState(() => _hata = e.toString());
    } finally {
      if (mounted) setState(() => _kaydediyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rol Seç')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('EduPlas’ta hangi rolde olacaksın?'),
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
            if (_hata != null) ...[
              const SizedBox(height: 12),
              Text(_hata!, style: const TextStyle(color: Colors.red)),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _kaydediyor ? null : _devamEt,
                child: _kaydediyor
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Devam'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
