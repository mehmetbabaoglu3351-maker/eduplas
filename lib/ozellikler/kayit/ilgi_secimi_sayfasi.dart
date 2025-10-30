// lib/ozellikler/kayit/ilgi_secimi_sayfasi.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:eduplas/router/route_names.dart';
import 'package:eduplas/cekirdek/akis/route_gate.dart';

class IlgiSecimiSayfasi extends StatefulWidget {
  static const route = RouteNames.ilgiSec;
  const IlgiSecimiSayfasi({super.key});

  @override
  State<IlgiSecimiSayfasi> createState() => _IlgiSecimiSayfasiState();
}

class _IlgiSecimiSayfasiState extends State<IlgiSecimiSayfasi> {
  // EduPlas Master Senaryo v1.1 — temel ilgi havuzu
  static const List<String> _ilgiHavuzu = <String>[
    'Kodlama',
    'Matematik',
    'Fen',
    'Müzik',
    'Sanat',
    'Spor',
    'Yabancı Dil',
    'Robotik',
  ];

  final Set<String> _secimler = <String>{};
  bool _islem = false;

  Map<String, dynamic> get _args {
    final data = ModalRoute.of(context)?.settings.arguments;
    if (data is Map<String, dynamic>) return data;
    return const <String, dynamic>{};
  }

  bool get _devBypass => (_args['devBypass'] == true);
  String? get _devFakeUid {
    final v = _args['devFakeUid'];
    return v is String ? v : null;
  }

  Future<void> _ileri() async {
    if (_secimler.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('En az bir ilgi alanı seçin.')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    final bool isDev = _devBypass || user == null;

    setState(() => _islem = true);
    try {
      if (!isDev) {
        // GERÇEK AKIŞ: registrations/{uid} altına yazar
        final regRef = FirebaseFirestore.instance.collection('registrations').doc(user.uid);
        await regRef.set({
          'interests': _secimler.toList(),
          'interestsUpdatedAt': FieldValue.serverTimestamp(),
          'interestsUpdatedBy': user.uid,
          'args': _args,
        }, SetOptions(merge: true));
      } else {
        // DEV AKIŞ: yazmaya çalış, hata gelirse önemseme
        final fakeUid = _devFakeUid ?? 'dev_fake_uid';
        try {
          final regRef = FirebaseFirestore.instance.collection('registrations').doc(fakeUid);
          await regRef.set({
            'interests': _secimler.toList(),
            'interestsUpdatedAt': FieldValue.serverTimestamp(),
            'interestsUpdatedBy': fakeUid,
            'args': _args,
            'dev': true,
          }, SetOptions(merge: true));
        } catch (e) {
          // burada log atıp devam edeceğiz
          debugPrint('[ILGI] DEV MODE: kayıt yazılamadı: $e');
        }
      }

      // Akış bayrağı
      RouteGate.ilgiOk = true;
      RouteGate.dump();

      if (!mounted) return;
      final nextArgs = {
        ..._args,
        'interests': _secimler.toList(),
      };
      await Navigator.pushNamed(context, RouteNames.sozlesmeKabul, arguments: nextArgs);
    } catch (e) {
      if (!mounted) return;
      if (isDev) {
        // dev/test: hata olsa bile akışı kesme
        debugPrint('[ILGI] DEV MODE hata ama devam: $e');
        await Navigator.pushNamed(
          context,
          RouteNames.sozlesmeKabul,
          arguments: {
            ..._args,
            'interests': _secimler.toList(),
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('İlgi alanları kaydedilemedi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _islem = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDevView = _devBypass || _devFakeUid != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('İlgi Alanları'),
        // dev akışı görsel olarak da belli olsun
        bottom: isDevView
            ? const PreferredSize(
                preferredSize: Size.fromHeight(26),
                child: Padding(
                  padding: EdgeInsets.only(bottom: 6),
                  child: Text(
                    'DEV AKIŞI: Test kullanıcısı ile devam ediyorsun.',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              )
            : null,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('İlgi alanlarını seç', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _ilgiHavuzu.map((etiket) {
                      final sel = _secimler.contains(etiket);
                      return FilterChip(
                        label: Text(etiket),
                        selected: sel,
                        onSelected: (v) {
                          setState(() {
                            if (v) {
                              _secimler.add(etiket);
                            } else {
                              _secimler.remove(etiket);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _islem ? null : _ileri,
                      icon: _islem
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.assignment_turned_in),
                      label: Text(_islem ? 'Kaydediliyor...' : 'Sözleşmeye Geç'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
