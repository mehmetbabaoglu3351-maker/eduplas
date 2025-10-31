// lib/ozellikler/kayit/rol_secimi_sayfasi.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:eduplas/router/route_names.dart';

/// EduPlas A2 – Rol Seçimi ve Profil Başlatma
/// - "Baş Admin" yalnızca ilk defa sistem kurulurken görünür.
/// - Eğer Firestore'da zaten bir "Baş Admin" varsa, bu seçenek listeden kalkar.
/// - Ek olarak "Ülke Admini" rolü eklendi.
class RolSecimiSayfasi extends StatefulWidget {
  static const route = RouteNames.rolSec;
  const RolSecimiSayfasi({super.key});

  @override
  State<RolSecimiSayfasi> createState() => _RolSecimiSayfasiState();
}

class _RolSecimiSayfasiState extends State<RolSecimiSayfasi> {
  final _roller = <String>[
    'Öğrenci',
    'Öğretmen',
    'Sınıf Başkanı',
    'Koordinatör',
    'İlçe Admin',
    'İl Admin',
    'Ülke Admini',
    'Baş Admin',
    'Destekçi',
    'İşyeri',
  ];

  String? _seciliRol;
  bool _kaydediyor = false;
  bool _yukleniyor = true;
  String? _hata;
  List<String> _gorunenRoller = [];

  @override
  void initState() {
    super.initState();
    _kontrolEtVeRolleriHazirla();
  }

  Future<void> _kontrolEtVeRolleriHazirla() async {
    try {
      // Firestore'da herhangi bir "Baş Admin" var mı kontrol et
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('rol', isEqualTo: 'Baş Admin')
          .limit(1)
          .get();

      final basAdminVar = snapshot.docs.isNotEmpty;

      setState(() {
        _gorunenRoller = List<String>.from(_roller);
        if (basAdminVar) {
          _gorunenRoller.remove('Baş Admin');
        }
        _yukleniyor = false;
      });
    } catch (e) {
      setState(() {
        _hata = 'Rol listesi yüklenemedi: $e';
        _yukleniyor = false;
      });
    }
  }

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
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
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
    if (_yukleniyor) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Rol Seçimi')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'EduPlas’ta hangi rolde olacaksın?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _gorunenRoller.map((rol) {
                    final secili = _seciliRol == rol;
                    return ChoiceChip(
                      label: Text(rol),
                      selected: secili,
                      selectedColor: Colors.teal.shade200,
                      onSelected: (_) {
                        setState(() => _seciliRol = rol);
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
            if (_hata != null) ...[
              const SizedBox(height: 12),
              Text(_hata!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _kaydediyor || _seciliRol == null ? null : _devamEt,
                child: _kaydediyor
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Devam Et'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
