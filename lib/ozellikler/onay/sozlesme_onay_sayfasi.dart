// lib/ozellikler/onay/sozlesme_onay_sayfasi.dart
import 'package:flutter/material.dart';
import 'package:eduplas/router/route_names.dart';

class SozlesmeOnaySayfasi extends StatefulWidget {
  static const route = RouteNames.legal;
  const SozlesmeOnaySayfasi({super.key});

  @override
  State<SozlesmeOnaySayfasi> createState() => _SozlesmeOnaySayfasiState();
}

class _SozlesmeOnaySayfasiState extends State<SozlesmeOnaySayfasi> {
  bool _okSoz = false;
  bool _okRiza = false;
  bool _okAyd = false;
  bool _okGiz = false;

  final _scrolls = List.generate(4, (_) => ScrollController());

  @override
  void dispose() {
    for (final c in _scrolls) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _hepsiOk => _okSoz && _okRiza && _okAyd && _okGiz;

  bool _sonunaIndiMi(ScrollController c) {
    final max = c.position.maxScrollExtent;
    final off = c.offset;
    return off >= max;
  }

  Future<void> _kabulEt() async {
    if (!_hepsiOk) return;
    // Not: Burada vSozlesme/vRiza/vAyd/vGiz ve legalAcceptedAt yazılacak.
    if (!mounted) return;
    await Navigator.pushNamedAndRemoveUntil(
      context,
      RouteNames.user,
      (r) => false,
    );
  }

  Widget _metinKarti({
    required String baslik,
    required int index,
    required ValueChanged<bool> onOkChanged,
  }) {
    final controller = _scrolls[index];
    final isOk = switch (index) {
      0 => _okSoz,
      1 => _okRiza,
      2 => _okAyd,
      _ => _okGiz,
    };

    return Card(
      child: SizedBox(
        height: 180,
        child: Column(
          children: [
            ListTile(title: Text(baslik)),
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: (n) {
                  if (n is ScrollEndNotification && _sonunaIndiMi(controller)) {
                    onOkChanged(true);
                  }
                  return false;
                },
                child: Scrollbar(
                  controller: controller,
                  child: ListView.builder(
                    controller: controller,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: 16,
                    itemBuilder: (_, i) => Text('$baslik — madde ${i + 1}'),
                  ),
                ),
              ),
            ),
            CheckboxListTile(
              title: const Text('Okudum ve kabul ediyorum'),
              value: isOk,
              onChanged: (val) => onOkChanged(val ?? false),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Not: Gerekirse ModalRoute ile args alınır (nick, phone vs.)
    return Scaffold(
      appBar: AppBar(title: const Text('Sözleşme Onayı')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _metinKarti(
              baslik: 'Kullanım Koşulları',
              index: 0,
              onOkChanged: (v) => setState(() => _okSoz = v),
            ),
            _metinKarti(
              baslik: 'Açık Rıza Metni',
              index: 1,
              onOkChanged: (v) => setState(() => _okRiza = v),
            ),
            _metinKarti(
              baslik: 'Aydınlatma Metni',
              index: 2,
              onOkChanged: (v) => setState(() => _okAyd = v),
            ),
            _metinKarti(
              baslik: 'Gizlilik Politikası',
              index: 3,
              onOkChanged: (v) => setState(() => _okGiz = v),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _hepsiOk ? _kabulEt : null,
                child: const Text('Tümünü kabul et ve devam et'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


