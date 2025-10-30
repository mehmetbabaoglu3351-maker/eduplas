// lib/ozellikler/kayit/rol_secimi_sayfasi.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:eduplas/router/route_names.dart';
import 'package:eduplas/cekirdek/akis/route_gate.dart';

class RolSecimiSayfasi extends StatefulWidget {
  static const route = RouteNames.rolSec;
  const RolSecimiSayfasi({super.key});

  @override
  State<RolSecimiSayfasi> createState() => _RolSecimiSayfasiState();
}

class _RolSecimiSayfasiState extends State<RolSecimiSayfasi> {
  // EduPlas Master Senaryo v1.1 role listesi (bootstrap dahil)
  static const List<_RolInfo> _tumRoller = [
    _RolInfo(
      key: 'bas_admin',
      label: 'Baş Admin',
      aciklama: 'Kurucu/üst yönetim. İlk kurulumda tek seferlik.',
      rozetler: ['Oto onay (bootstrap)', 'Tam yetki'],
      requiresBootstrap: true,
    ),
    _RolInfo(
      key: 'admin',
      label: 'Admin',
      aciklama: 'Global yönetim. Ülke Adminlerini onaylar.',
      rozetler: ['Baş Admin onayı'],
    ),
    _RolInfo(
      key: 'ulke_admin',
      label: 'Ülke Admini',
      aciklama: 'Ülke düzeyi yönetim. İl Adminlerini onaylar.',
      rozetler: ['Admin onayı'],
    ),
    _RolInfo(
      key: 'il_admin',
      label: 'İl Admini',
      aciklama: 'İl düzeyi yönetim. Koordinatör onaylarını yürütür.',
      rozetler: ['Ülke Admini onayı'],
    ),
    _RolInfo(
      key: 'ilce_admin',
      label: 'İlçe Admini',
      aciklama: 'İlçe düzeyi yönetim. Koordinatörleri yönetir.',
      rozetler: ['İl Admini onayı'],
    ),
    _RolInfo(
      key: 'koordinator',
      label: 'Koordinatör',
      aciklama: 'Okul/kurum koordinasyonu, öğretmen onayı.',
      rozetler: ['İlçe/İl Admin onayı'],
    ),
    _RolInfo(
      key: 'ogretmen',
      label: 'Öğretmen',
      aciklama: 'Sınıf ve öğrenci yönetimi, içerik katkısı.',
      rozetler: ['Koordinatör onayı'],
    ),
    _RolInfo(
      key: 'ogrenci',
      label: 'Öğrenci',
      aciklama: 'Ders & etkinlik katılımı, öğren-kazan.',
      rozetler: ['Öğretmen onayı'],
    ),
    _RolInfo(
      key: 'isyeri',
      label: 'İşyeri (Üye İş Yeri)',
      aciklama: 'Üye iş yeri; kampanya, ödeme, havale talebi.',
      rozetler: ['Koordinatör onayı'],
    ),
    _RolInfo(
      key: 'destekci',
      label: 'Destekçi',
      aciklama: 'Bağış/katkı yapan kişi/kurum.',
      rozetler: ['Koordinatör onayı'],
    ),
  ];

  String? _secili;
  bool _islem = false;

  Map<String, dynamic> get _args {
    final data = ModalRoute.of(context)?.settings.arguments;
    if (data is Map<String, dynamic>) return data;
    return const <String, dynamic>{};
  }

  bool get _bootstrap => (_args['bootstrap'] == true);
  bool get _devBypass => (_args['devBypass'] == true);

  // Eğer devBypass geldiyse Baş Admin'i de gösterelim ki senaryoyu test edebilelim
  List<_RolInfo> get _gorunurRoller {
    if (_bootstrap) {
      return _tumRoller.where((r) => r.key == 'bas_admin').toList(growable: false);
    }
    if (_devBypass) {
      // dev'de her şeyi göster
      return _tumRoller;
    }
    return _tumRoller.where((r) => r.key != 'bas_admin').toList(growable: false);
  }

  _RolInfo? get _seciliRolInfo {
    final key = _secili;
    if (key == null) return null;
    return _gorunurRoller.firstWhere((r) => r.key == key, orElse: () => _gorunurRoller.first);
  }

  String? _approverFor(String rol) {
    switch (rol) {
      case 'admin':
        return 'bas_admin';
      case 'ulke_admin':
        return 'admin';
      case 'il_admin':
        return 'ulke_admin';
      case 'ilce_admin':
        return 'il_admin';
      case 'koordinator':
        return 'ilce_admin';
      case 'ogretmen':
        return 'koordinator';
      case 'ogrenci':
        return 'ogretmen';
      case 'destekci':
        return 'koordinator';
      case 'isyeri':
        return 'koordinator';
      default:
        return null; // bas_admin
    }
  }

  Future<void> _ileri() async {
    if (_secili == null) return;

    final authUser = FirebaseAuth.instance.currentUser;
    final bool isDev = _devBypass || authUser == null;
    // dev/test için sahte uid
    final String uid = authUser?.uid ?? 'dev_fake_uid';

    setState(() => _islem = true);
    try {
      final secilenRol = _secili!;
      final isBootstrapBasAdmin = _bootstrap && secilenRol == 'bas_admin';

      // Firestore'a sadece gerçek kullanıcı varsa zorunlu yaz
      if (!isDev) {
        final doc = FirebaseFirestore.instance.collection('registrations').doc(uid);
        final data = <String, dynamic>{
          'requestedRole': secilenRol,
          'status': isBootstrapBasAdmin ? 'approved' : 'pending',
          'requestedAt': FieldValue.serverTimestamp(),
          'requestedBy': uid,
          'args': _args,
          'approverRole': isBootstrapBasAdmin ? null : _approverFor(secilenRol),
        };
        if (isBootstrapBasAdmin) {
          data['approvedAt'] = FieldValue.serverTimestamp();
          data['approvedBy'] = 'system';
          data['approvalNote'] = 'bootstrap_auto';
        }
        await doc.set(data, SetOptions(merge: true));
      } else {
        // dev modda sadece log at
        debugPrint('[ROL] DEV MODE: kayıt yazılmadı. uid=$uid rol=$secilenRol');
      }

      RouteGate.rolIntentOk = true;
      RouteGate.dump();

      if (!mounted) return;
      final nextArgs = {
        ..._args,
        'requestedRole': secilenRol,
        if (isDev) 'devFakeUid': uid,
      };
      await Navigator.pushNamed(context, RouteNames.ilgiSec, arguments: nextArgs);
    } catch (e) {
      if (!mounted) return;
      // Dev modda hata olsa da ilerleyelim
      if (_devBypass) {
        debugPrint('[ROL] DEV MODE hata ama devam: $e');
        await Navigator.pushNamed(
          context,
          RouteNames.ilgiSec,
          arguments: {
            ..._args,
            'requestedRole': _secili!,
            'devFakeUid': 'dev_fake_uid',
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rol niyeti kaydedilemedi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _islem = false);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_secili == null && _gorunurRoller.isNotEmpty) {
      _secili = _gorunurRoller.first.key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bilgi = _bootstrap
        ? 'Kurulum (bootstrap) aktif: Yalnız ilk kurulumda Baş Admin seçilebilir ve otomatik onaylanır.'
        : _devBypass
            ? 'DEV mod aktif: Tüm roller görünür. Kayıt test amaçlıdır.'
            : 'Seçtiğin rol, onay sürecine iletilir. Onay sonrası yetkilerin tanımlanır.';

    final items = <DropdownMenuItem<String>>[
      for (final r in _gorunurRoller)
        DropdownMenuItem<String>(
          value: r.key,
          child: Text(r.label),
        ),
    ];

    final rolInfo = _seciliRolInfo;

    return Scaffold(
      appBar: AppBar(title: const Text('Rol Seçimi')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Platformdaki rolünü seç', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16),
                      const SizedBox(width: 6),
                      Expanded(child: Text(bilgi)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: _secili,
                    items: items,
                    decoration: const InputDecoration(
                      labelText: 'Rol',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onChanged: (v) => setState(() => _secili = v),
                  ),
                  if (rolInfo != null) ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        rolInfo.label,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(rolInfo.aciklama),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 6,
                        runSpacing: -8,
                        children: [
                          for (final z in rolInfo.rozetler)
                            Chip(
                              label: Text(z),
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _islem || _secili == null ? null : _ileri,
                      icon: _islem
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.arrow_forward),
                      label: Text(_islem ? 'Kaydediliyor...' : 'Devam'),
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

class _RolInfo {
  final String key;
  final String label;
  final String aciklama;
  final List<String> rozetler;
  final bool requiresBootstrap;

  const _RolInfo({
    required this.key,
    required this.label,
    required this.aciklama,
    this.rozetler = const [],
    this.requiresBootstrap = false,
  });
}
