// lib/cekirdek/konum/konum_adres_secici.dart
import 'dart:async';
import 'package:flutter/material.dart';

import 'package:eduplas/cekirdek/konum/konum_secici.dart';
import 'package:eduplas/cekirdek/konum/konum_servisi.dart';

/// Geriye dönük uyumluluk için tanım korunuyor.
/// Bu bileşen artık hiyerarşik yer seçimi yapmaz.
class SeciliYer {
  final String il;
  final String ilce;
  final String mahalle;
  const SeciliYer({required this.il, required this.ilce, required this.mahalle});
  Map<String, String> toMap() => {'il': il, 'ilce': ilce, 'mahalle': mahalle};
  @override
  String toString() => '$il / $ilce / $mahalle';
}

class KonumAdresSecici extends StatefulWidget {
  const KonumAdresSecici({
    super.key,
    this.konumButonu = true,
    this.onChanged,
    this.bilgiMetni = 'Cihaz konumun kaydınla birlikte kullanılacak.',
  });

  /// Konum butonunu göster
  final bool konumButonu;

  /// SeciliYer artık **her zaman null** döner.
  /// LocationFix cihazdan alınan koordinattır.
  final void Function(SeciliYer? secim, LocationFix? fix)? onChanged;

  /// Bilgi satırı
  final String bilgiMetni;

  @override
  State<KonumAdresSecici> createState() => _KonumAdresSeciciState();
}

class _KonumAdresSeciciState extends State<KonumAdresSecici> {
  LocationFix? _fix;
  String? _hata;
  bool _islem = false;

  void _emit() {
    widget.onChanged?.call(null, _fix);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final subtle = t.colorScheme.onSurfaceVariant.withValues(alpha: 0.80);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Teşhis bandı
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.teal.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.teal),
          ),
          child: const Text('Konum-Only bileşeni aktif'),
        ),

        if (widget.konumButonu)
          Row(
            children: [
              Expanded(
                child: Text(
                  _fix != null
                      ? 'Konum: ${_fix!.lat.toStringAsFixed(6)}, ${_fix!.lng.toStringAsFixed(6)} (~${(_fix!.accuracyM ?? 0).toStringAsFixed(1)} m)'
                      : 'Konumunu cihazdan alarak otomatik doldur.',
                  style: t.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _islem ? null : _onKonumAl,
                icon: _islem
                    ? const SizedBox(
                        width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.my_location_outlined),
                label: const Text('Konumumu al'),
              ),
            ],
          ),

        const SizedBox(height: 12),
        Text(widget.bilgiMetni, style: t.textTheme.bodySmall?.copyWith(color: subtle)),

        if (_hata != null) ...[
          const SizedBox(height: 8),
          Text(_hata!, style: const TextStyle(color: Colors.red)),
        ],
      ],
    );
  }

  Future<void> _onKonumAl() async {
    setState(() {
      _islem = true;
      _hata = null;
    });

    // Alt sayfada otomatik konum alma akışı; kullanıcı onaylayınca fix döner
    final fix = await showModalBottomSheet<LocationFix?>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Konumunu al', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 12),
              KonumSecici(
                otomatikKonumButonu: true,
                onFix: (f) => Navigator.of(ctx).pop(f),
                bilgiMetni: 'Konum koordinatların kaydında kullanılacak.',
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );

    if (!mounted) return;

    setState(() {
      _islem = false;
      if (fix != null) {
        _fix = fix;
      } else if (_fix == null) {
        _hata = 'Konum alınamadı. Tekrar dene veya tarayıcı/cihaz izinlerini kontrol et.';
      }
    });

    _emit();
  }
}


