// lib/ozellikler/onay/sozlesme_kabul_sayfasi.dart
// EduPlas Master Senaryo v1.1 – Sprint-1 Legal Adımı
// Bu ekran olmadan kayıt tamamlanamaz.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:eduplas/router/route_names.dart';

class SozlesmeKabulSayfasi extends StatefulWidget {
  static const route = RouteNames.sozlesmeKabul;

  const SozlesmeKabulSayfasi({super.key});

  @override
  State<SozlesmeKabulSayfasi> createState() => _SozlesmeKabulSayfasiState();
}

class _SozlesmeKabulSayfasiState extends State<SozlesmeKabulSayfasi> {
  // NOT: Bu URL’leri istersen Firestore’dan da çektirebiliriz.
  // Şimdilik sabit verdim ki 1 ve 2 de çalışsın.
  static const String _kullaniciSozlesmesiUrl =
      'https://eduplas.fake/legal/kullanici-sozlesmesi';
  static const String _aydinlatmaMetniUrl =
      'https://eduplas.fake/legal/aydinlatma-metni';
  static const String _acikRizaUrl =
      'https://eduplas.fake/legal/acik-riza';

  bool _kullaniciSozlesmesiOkundu = false;
  bool _aydinlatmaMetniOkundu = false;
  bool _acikRizaOkundu = false;

  bool _islemde = false;

  Future<void> _acUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await canLaunchUrl(uri)) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bağlantı açılamadı.')),
      );
      return;
    }
    await launchUrl(
      uri,
      mode: LaunchMode.inAppBrowserView,
    );
  }

  bool get _hepsiKabul =>
      _kullaniciSozlesmesiOkundu &&
      _aydinlatmaMetniOkundu &&
      _acikRizaOkundu;

  void _tamamla() async {
    if (!_hepsiKabul) return;
    setState(() {
      _islemde = true;
    });

    // Buraya senin gerçek kayıt / Firestore update / onay kaydı gelecek.
    // Şimdilik sadece sonraki sayfaya geçelim.
    // ignore: use_build_context_synchronously
    Navigator.of(context).pushReplacementNamed(RouteNames.user);

    setState(() {
      _islemde = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sözleşme Onayı'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Logo / başlık alanı
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EduPlas',
                  style: tema.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Öğren kazan, öğret kazandır.',
                  style: tema.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  'Lütfen aşağıdaki belgeleri okuyup onaylayın.',
                  style: tema.textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 1) Kullanıcı Sözleşmesi
            _LegalSatiri(
              no: 1,
              baslik: 'Kullanıcı Sözleşmesi',
              aciklama:
                  'EduPlas platformunu kullanmanın temel koşullarıdır.',
              url: _kullaniciSozlesmesiUrl,
              deger: _kullaniciSozlesmesiOkundu,
              onDegisti: (v) {
                setState(() {
                  _kullaniciSozlesmesiOkundu = v;
                });
              },
              onLink: _kullaniciSozlesmesiUrl.isEmpty
                  ? null
                  : () => _acUrl(_kullaniciSozlesmesiUrl),
            ),

            const SizedBox(height: 12),

            // 2) Aydınlatma Metni
            _LegalSatiri(
              no: 2,
              baslik: 'Aydınlatma Metni (KVKK)',
              aciklama:
                  'Kişisel verilerinizin hangi amaçlarla işlendiğini açıklar.',
              url: _aydinlatmaMetniUrl,
              deger: _aydinlatmaMetniOkundu,
              onDegisti: (v) {
                setState(() {
                  _aydinlatmaMetniOkundu = v;
                });
              },
              onLink: _aydinlatmaMetniUrl.isEmpty
                  ? null
                  : () => _acUrl(_aydinlatmaMetniUrl),
            ),

            const SizedBox(height: 12),

            // 3) Açık Rıza
            _LegalSatiri(
              no: 3,
              baslik: 'Açık Rıza / Onay Formu',
              aciklama:
                  'Ek hizmetler, kampanyalar ve konum temelli içerik için gereklidir.',
              url: _acikRizaUrl,
              deger: _acikRizaOkundu,
              onDegisti: (v) {
                setState(() {
                  _acikRizaOkundu = v;
                });
              },
              onLink: _acikRizaUrl.isEmpty ? null : () => _acUrl(_acikRizaUrl),
            ),

            const SizedBox(height: 32),

            FilledButton.icon(
              onPressed: _hepsiKabul && !_islemde ? _tamamla : null,
              icon: _islemde
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: const Text('Kabul ediyorum ve devam et'),
            ),

            const SizedBox(height: 16),
            Text(
              'Not: Kabul etmeden EduPlas hesabınız tamamlanmaz.',
              style: tema.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _LegalSatiri extends StatelessWidget {
  final int no;
  final String baslik;
  final String aciklama;
  final String url;
  final bool deger;
  final ValueChanged<bool> onDegisti;
  final VoidCallback? onLink;

  const _LegalSatiri({
    required this.no,
    required this.baslik,
    required this.aciklama,
    required this.url,
    required this.deger,
    required this.onDegisti,
    this.onLink,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: tema.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: deger,
            onChanged: (v) {
              if (v != null) {
                onDegisti(v);
              }
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$no. $baslik',
                  style: tema.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  aciklama,
                  style: tema.textTheme.bodySmall,
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: onLink,
                    icon: const Icon(Icons.open_in_new),
                    label: Text(
                      onLink == null ? 'Bağlantı yok' : 'Görüntüle',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
