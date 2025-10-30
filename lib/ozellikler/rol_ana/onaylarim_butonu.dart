import 'package:flutter/material.dart';
import '../onay/onay_sayfasi.dart';

class OnaylarimButonu extends StatelessWidget {
  final String role;
  const OnaylarimButonu({super.key, required this.role});

  bool get _onayciMi {
    final r = role.toLowerCase();
    return r.contains('baş admin') ||
        r.contains('bas admin') ||
        r.contains('il admin') ||
        r.contains('ilçe admin') ||
        r.contains('ilce admin') ||
        r.contains('koordinatör') ||
        r.contains('koordinator') ||
        r.contains('öğretmen') ||
        r.contains('ogretmen');
  }

  @override
  Widget build(BuildContext context) {
    if (!_onayciMi) return const SizedBox.shrink();
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () => Navigator.of(context).pushNamed(OnaySayfasi.route),
        icon: const Icon(Icons.inbox_outlined),
        label: const Text('Onaylarım'),
      ),
    );
  }
}


