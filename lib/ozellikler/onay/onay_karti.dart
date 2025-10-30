// lib/ozellikler/onay/onay_karti.dart
import 'package:flutter/material.dart';
import 'onay_servisi.dart';

class OnayKarti extends StatelessWidget {
  final Basvuru basvuru;
  final String currentUid;
  const OnayKarti({super.key, required this.basvuru, required this.currentUid});

  @override
  Widget build(BuildContext context) {
    final ad = (basvuru.profilAdSoyad?.trim().isNotEmpty ?? false)
        ? basvuru.profilAdSoyad!.trim()
        : basvuru.takmaAd;

    // Konumu tek yerden çöz: artık sadece location kullanıyoruz
    final k = OnayServisi.cozKonum(basvuru.location);

    String konumYazi = '';
    if (k.il.isNotEmpty) konumYazi = k.il;
    if (k.ilce.isNotEmpty) {
      konumYazi = konumYazi.isEmpty ? k.ilce : '$konumYazi • ${k.ilce}';
    }
    if (k.mahalle.isNotEmpty) {
      konumYazi = konumYazi.isEmpty ? k.mahalle : '$konumYazi • ${k.mahalle}';
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık: Ad (Rol)
            Text(
              '$ad (${basvuru.requestedRole})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            // Konum
            if (konumYazi.isNotEmpty)
              Text(
                konumYazi,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.black.withValues(alpha: 0.6),
                    ),
              ),
            if (basvuru.telefon.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Tel: ${basvuru.telefon}'),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.close),
                    label: const Text('Reddet'),
                    onPressed: () async {
                      await OnayServisi().reddet(
                        b: basvuru,
                        reddedenUid: currentUid,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Başvuru reddedildi.')),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text('Onayla'),
                    onPressed: () async {
                      await OnayServisi().onayla(
                        b: basvuru,
                        onaylayanUid: currentUid,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Başvuru onaylandı.')),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


