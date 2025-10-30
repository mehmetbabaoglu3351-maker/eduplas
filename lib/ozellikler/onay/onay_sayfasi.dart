// lib/ozellikler/onay/onay_sayfasi.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'onay_servisi.dart';
import 'onay_karti.dart';
import 'package:eduplas/cekirdek/arayuz/app_logo.dart';
import 'package:eduplas/router/route_names.dart';

class OnaySayfasi extends StatefulWidget {
  static const route = RouteNames.onay;
  const OnaySayfasi({super.key});

  @override
  State<OnaySayfasi> createState() => _OnaySayfasiState();
}

class _OnaySayfasiState extends State<OnaySayfasi> {
  String _role = '';
  String _il = '';
  String _ilce = '';
  String _mahalle = '';
  String _uid = '';
  bool _hazir = false;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Oturum yoksa bile panel açılabilsin (erken çıkışta bilgi kartı göstereceğiz)
      if (mounted) setState(() => _hazir = true);
      return;
    }
    _uid = user.uid;

    try {
      final u = await FirebaseFirestore.instance.collection('users').doc(_uid).get();
      final m = u.data() ?? <String, dynamic>{};

      _role = (m['role'] ?? '').toString();

      // Sadece location’dan çöz. Eski alanlar geri uyumluluk için okunuyor.
      final Map<String, dynamic>? loc =
          m['location'] is Map<String, dynamic> ? m['location'] as Map<String, dynamic> : null;

      final k = OnayServisi.cozKonum(
        loc,
        il: (m['il'] ?? '').toString(),
        ilce: (m['ilce'] ?? '').toString(),
        mahalle: (m['mahalle'] ?? '').toString(),
      );
      _il = k.il;
      _ilce = k.ilce;
      _mahalle = k.mahalle;
    } catch (_) {
      // Sessiz geç
    } finally {
      if (mounted) setState(() => _hazir = true);
    }
  }

  void _devamEtKullanici() {
    Navigator.of(context).pushNamedAndRemoveUntil(RouteNames.user, (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_hazir) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Erken çıkış: kullanıcı veya rol boşsa stream’e girmeden bilgi kartı göster.
    if (_uid.isEmpty || _role.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Onay Bekleyen Başvurular')),
        body: const _BilgiKartBosRol(),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _devamEtKullanici,
          icon: const Icon(Icons.arrow_forward),
          label: const Text('Devam Et'),
        ),
      );
    }

    final stream = OnayServisi().bekleyenBasvurulariDinle(
      currentUid: _uid,
      currentUserRole: _role,
      il: _il,
      ilce: _ilce,
      mahalle: _mahalle,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Onay Bekleyen Başvurular'),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          const Center(child: AppLogo(daire: true)),
          const SizedBox(height: 4),
          Text(
            'EduPlas Onay Paneli',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF00BFA5),
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<List<Basvuru>>(
              stream: stream,
              builder: (context, snap) {
                if (snap.hasError) {
                  return _HataGorunumu(
                    message:
                        'Onay listesi alınırken hata oluştu.\n${snap.error}',
                    onRetry: _yukle,
                    onSkip: _devamEtKullanici,
                  );
                }

                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final list = snap.data ?? <Basvuru>[];
                if (list.isEmpty) {
                  return const _BosGorunum();
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    return OnayKarti(
                      basvuru: list[i],
                      currentUid: _uid,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BosGorunum extends StatelessWidget {
  const _BosGorunum();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.verified_user_outlined, size: 64),
          SizedBox(height: 12),
          Text('Şu an onay bekleyen başvuru yok'),
        ],
      ),
    );
  }
}

class _BilgiKartBosRol extends StatelessWidget {
  const _BilgiKartBosRol();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Aktif oturum veya rol bulunamadı.\n'
                    'Sözleşme kabulü “cihazda” kaydedilmiş olabilir. Devam ederek kullanıcı ekranına geçebilirsin.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HataGorunumu extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onSkip;

  const _HataGorunumu({
    required this.message,
    required this.onRetry,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 36),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Yeniden Dene'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: onSkip,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Devam Et'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


