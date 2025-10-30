import 'package:flutter/material.dart';

class BeklemedeSayfasi extends StatelessWidget {
  final String baslik;
  final String aciklama;
  final bool reddedildi;

  const BeklemedeSayfasi({
    super.key,
    this.baslik = 'Başvurun alındı',
    this.aciklama = 'Onay sürecin devam ediyor. Lütfen beklemede kal.',
    this.reddedildi = false,
  });

  @override
  Widget build(BuildContext context) {
    final renk = reddedildi ? Colors.red : Colors.orange;
    final ikon = reddedildi ? Icons.cancel_outlined : Icons.hourglass_bottom;

    return Scaffold(
      appBar: AppBar(title: const Text('Durum')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(ikon, size: 64, color: renk),
                  const SizedBox(height: 12),
                  Text(
                    baslik,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    aciklama,
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    reddedildi
                        ? 'Tekrar kayıt yapabilir veya destek talep edebilirsin.'
                        : 'Onaylandığında seni otomatik olarak yönlendireceğiz.',
                    style: TextStyle(fontSize: 13, color: renk),
                    textAlign: TextAlign.center,
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


