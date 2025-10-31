// lib/hukuk/sozlesme_okuma_sayfasi.dart
// Kaynak: assets/hukuk/eduplas_sozlesme_tr.txt ve eduplas_sozlesme_en.txt
// Özellikler:
// - Sistemin diline göre TR / EN asset açar
// - Kullanıcı metni en alta kadar kaydırmadan onay veremez (opsiyonel parametre)
// - Onaylanınca çağıran sayfaya "true" döner

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

class SozlesmeOkumaSayfasi extends StatefulWidget {
  final bool scrollZorunlu;

  const SozlesmeOkumaSayfasi({
    super.key,
    this.scrollZorunlu = true,
  });

  @override
  State<SozlesmeOkumaSayfasi> createState() => _SozlesmeOkumaSayfasiState();
}

class _SozlesmeOkumaSayfasiState extends State<SozlesmeOkumaSayfasi> {
  final _scrollController = ScrollController();

  String _metin = 'Yükleniyor...';
  bool _sonunaInildi = false;
  bool _okudumKabul = false;
  bool _yukleniyor = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollDinle);
    _metniYukle();
  }

  Future<void> _metniYukle() async {
    final localeCode = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    final assetPath = localeCode == 'tr'
        ? 'assets/hukuk/eduplas_sozlesme_tr.txt'
        : 'assets/hukuk/eduplas_sozlesme_en.txt';

    try {
      final data = await rootBundle.loadString(assetPath);
      if (mounted) {
        setState(() {
          _metin = data;
          _yukleniyor = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _metin = 'Sözleşme metni yüklenemedi. Lütfen yöneticinizle iletişime geçin.';
          _yukleniyor = false;
        });
      }
    }
  }

  void _scrollDinle() {
    if (!widget.scrollZorunlu) return;
    if (!_scrollController.hasClients) return;

    final max = _scrollController.position.maxScrollExtent;
    final pos = _scrollController.position.pixels;

    // En alta %95 içinde ise "okundu" kabul et
    if (pos >= max * 0.95) {
      if (!_sonunaInildi) {
        setState(() {
          _sonunaInildi = true;
        });
      }
    }
  }

  bool get _butonAktif {
    if (widget.scrollZorunlu) {
      return _sonunaInildi && _okudumKabul;
    }
    return _okudumKabul;
  }

  void _onayla() {
    if (!_butonAktif) return;
    Navigator.of(context).pop(true);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollDinle);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('EduPlas Sözleşme'),
      ),
      body: Column(
        children: [
          Expanded(
            child: _yukleniyor
                ? const Center(child: CircularProgressIndicator())
                : Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _metin,
                        style: tema.textTheme.bodyMedium,
                      ),
                    ),
                  ),
          ),
          const Divider(height: 1),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                CheckboxListTile(
                  value: _okudumKabul,
                  onChanged: (v) {
                    setState(() {
                      _okudumKabul = v ?? false;
                    });
                  },
                  title: const Text('EduPlas Genel Sözleşmesini okudum, onaylıyorum.'),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _butonAktif ? _onayla : null,
                    icon: const Icon(Icons.check),
                    label: const Text('Onayla ve devam et'),
                  ),
                ),
                if (widget.scrollZorunlu && !_sonunaInildi)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Metnin sonuna kadar inmeden onay veremezsiniz.',
                      style: tema.textTheme.bodySmall?.copyWith(
                        color: tema.colorScheme.error,
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
