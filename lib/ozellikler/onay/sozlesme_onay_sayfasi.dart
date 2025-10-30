// lib/ozellikler/onay/sozlesme_onay_sayfasi.dart
import 'package:flutter/material.dart';
import 'package:eduplas/router/route_names.dart';

class SozlesmeOnaySayfasi extends StatelessWidget {
  // yine sabit string
  static const route = '/onay/sozlesme';

  const SozlesmeOnaySayfasi({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sözleşme Onayı'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sözleşme onaylarınız başarıyla alındı.'),
            const SizedBox(height: 12),
            if (args != null)
              Text('Ek bilgi: ${args.toString()}'),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(
                    context,
                    RouteNames.user,
                  );
                },
                child: const Text('Ana sayfaya git'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
