// lib/ozellikler/konum/konum_secici.dart
//
// Konum-Only v1
// Minimal bileşen: "Konumumu al" butonu + alınan koordinatların gösterimi.
// İl–ilçe–mahalle yok, YerVeriServisi yok.
//
// Kullanım örneği:
// KonumSecici(
//   otomatikKonumButonu: true,
//   onFix: (fix) { /* fix.toMap() ile kaydet */ },
// )

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../cekirdek/konum/konum_servisi.dart';

class KonumSecici extends StatefulWidget {
  const KonumSecici({
    super.key,
    this.otomatikKonumButonu = true,
    this.onFix,
    this.bilgiMetni = 'Konum koordinatların kaydınla birlikte kullanılacak.',
  });

  /// Butonu göster
  final bool otomatikKonumButonu;

  /// Konum başarıyla alındığında çağrılır
  final ValueChanged<LocationFix>? onFix;

  /// Alt bilgi
  final String bilgiMetni;

  @override
  State<KonumSecici> createState() => _KonumSeciciState();
}

class _KonumSeciciState extends State<KonumSecici> {
  final _svc = KonumServisi.instance;

  LocationFix? _fix;
  String? _hata;
  bool _calisiyor = false;

  Future<void> _konumuAl() async {
    setState(() {
      _hata = null;
      _calisiyor = true;
    });

    try {
      final fix = await _svc.getCurrentFix();
      if (!mounted) return;
      setState(() => _fix = fix);
      widget.onFix?.call(fix);
    } on PermissionDefinitionsNotFoundException {
      if (!mounted) return;
      setState(() {
        _hata = 'Platform izin tanımları eksik (AndroidManifest/Info.plist).';
      });
    } on LocationServiceDisabledException {
      if (!mounted) return;
      setState(() {
        _hata = 'Konum servisi kapalı. Lütfen cihazında GPS’i aç.';
      });
    } on PermissionDeniedException {
      if (!mounted) return;
      setState(() {
        _hata = 'Konum izni reddedildi. Ayarlardan izin ver.';
      });
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _hata = 'Konum isteği zaman aşımına uğradı. Tekrar dene.';
      });
    } on StateError catch (e) {
      if (!mounted) return;
      setState(() {
        _hata = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hata = 'Konum alınamadı: $e';
      });
    } finally {
      if (mounted) setState(() => _calisiyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final subtle = t.colorScheme.onSurfaceVariant.withValues(alpha: 0.80);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _fix != null
                    ? 'Konum: ${_fix!.lat.toStringAsFixed(6)}, ${_fix!.lng.toStringAsFixed(6)}  (~${(_fix!.accuracyM ?? 0).toStringAsFixed(1)} m)'
                    : 'Konum alınmadı',
              ),
            ),
            const SizedBox(width: 12),
            if (widget.otomatikKonumButonu)
              ElevatedButton.icon(
                onPressed: _calisiyor ? null : _konumuAl,
                icon: _calisiyor
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location_outlined),
                label: Text(_calisiyor ? 'Alınıyor...' : 'Konumumu al'),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          widget.bilgiMetni,
          style: t.textTheme.bodySmall?.copyWith(color: subtle),
          textAlign: TextAlign.start,
        ),
        if (_hata != null) ...[
          const SizedBox(height: 6),
          Text(_hata!, style: const TextStyle(color: Colors.red)),
        ],
      ],
    );
  }
}


