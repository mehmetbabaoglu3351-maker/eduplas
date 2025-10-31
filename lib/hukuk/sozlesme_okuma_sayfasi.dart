import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:eduplas/cekirdek/arayuz/app_logo.dart';
import 'package:eduplas/cekirdek/dil/dil_yoneticisi.dart';

/// EduPlas Tek Sözleşme Ekranı
/// (Tüm hukuki metinler bu tek dosyada birleşiktir)
class SozlesmeOkumaSayfasi extends StatefulWidget {
  const SozlesmeOkumaSayfasi({super.key});

  @override
  State<SozlesmeOkumaSayfasi> createState() => _SozlesmeOkumaSayfasiState();
}

class _SozlesmeOkumaSayfasiState extends State<SozlesmeOkumaSayfasi> {
  String? _metin;
  String? _hata;
  bool _yukleniyor = true;
  late final String _aktifDil;

  @override
  void initState() {
    super.initState();
    _aktifDil = DilYoneticisi.instance.aktifDil;
    _yukle();
  }

  Future<void> _yukle() async {
    setState(() {
      _yukleniyor = true;
      _hata = null;
    });

    final dosyaYolu = _aktifDil.startsWith('en')
        ? 'assets/hukuk/eduplas_sozlesme_en.txt'
        : 'assets/hukuk/eduplas_sozlesme_tr.txt';

    try {
      final txt = await rootBundle.loadString(dosyaYolu);
      if (!mounted) return;
      setState(() {
        _metin = txt;
      });
    } catch (e) {
      setState(() {
        _hata = 'Sözleşme dosyası yüklenemedi: $dosyaYolu\n$e';
        _metin = _varsayilanSozlesme;
      });
    } finally {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('EduPlas Sözleşme')),
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Center(child: AppLogo(daire: true, compactHint: true)),
                        const SizedBox(height: 8),
                        Text(
                          'EduPlas',
                          textAlign: TextAlign.center,
                          style: tema.textTheme.titleLarge?.copyWith(
                                color: const Color(0xFF00BFA5),
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Text(
                              _metin ?? '',
                              style: const TextStyle(fontSize: 14, height: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_hata != null)
                          Text(
                            _hata!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Okudum, anladım'),
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

const String _varsayilanSozlesme = '''
EDUPLAS TEK SÖZLEŞME (GEÇİCİ)
Bu metin, dosya yüklenemediğinde gösterilir.
''';
