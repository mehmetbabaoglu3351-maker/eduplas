// lib/diagnostics/asset_selftest.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';

/// Basit asset tanı testi:
/// - Sadece kullanılan gerçek yolu dener: assets/veri/yerler/tr.json
/// - AssetManifest içinde var mı yok mu kontrol eder.
/// - Hataları kullanıcıya anlaşılır şekilde gösterir.
class AssetSelfTest extends StatefulWidget {
  const AssetSelfTest({super.key});

  @override
  State<AssetSelfTest> createState() => _AssetSelfTestState();
}

class _AssetSelfTestState extends State<AssetSelfTest> {
  static const String _path = 'assets/veri/yerler/tr.json';

  String _log = '🔎 [ASSET TEST] Başladı\n';
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    try {
      // 1) AssetManifest içinde kayıtlı mı?
      final manifest = await rootBundle.loadString('AssetManifest.json');
      final hasInManifest = manifest.contains(_path);
      _append('• Manifest: $_path var mı?   $hasInManifest');

      // 2) Dosyayı gerçekten yükleyebiliyor muyuz?
      String txt = '';
      try {
        txt = await rootBundle.loadString(_path);
        if (txt.trim().isEmpty) {
          _append('• $_path -> ERR: Boş içerik döndü.');
        } else {
          _append('• $_path -> OK: ${txt.length} bayt');
          // Minimal JSON kontrolü
          try {
            final map = json.decode(txt) as Map<String, dynamic>;
            final iller = map['iller'];
            _append('• JSON: iller listesi var mı? ${iller is List}');
          } catch (e) {
            _append('• JSON parse uyarısı: $e');
          }
        }
      } catch (e) {
        _append('• $_path -> ERR: Yüklenemedi: $e');
      }
    } catch (e) {
      _append('GENEL HATA: $e');
    } finally {
      _append('✅ [ASSET TEST] Bitti');
      setState(() => _done = true);
    }
  }

  void _append(String line) {
    if (kDebugMode) debugPrint(line);
    setState(() => _log += '$line\n');
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Asset Tanı', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Text(_log, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: _done ? _run : null,
                child: const Text('Tekrar Dene'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


