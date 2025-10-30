// lib/ayarlar/dil_secimi_sayfasi.dart
import 'package:flutter/material.dart';
import 'package:eduplas/main.dart'; // EduPlasApp.of(...)
import 'package:eduplas/l10n/supported_locales.dart'; // kSupportedLocales

class DilSecimiSayfasi extends StatefulWidget {
  const DilSecimiSayfasi({super.key});

  @override
  State<DilSecimiSayfasi> createState() => _DilSecimiSayfasiState();
}

class _DilSecimiSayfasiState extends State<DilSecimiSayfasi> {
  late Locale _secili;
  bool _inited = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // context'e güvenli erişim için init'i burada yapıyoruz
    if (!_inited) {
      _secili = Localizations.localeOf(context);
      _inited = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    // prefer_const_declarations uyarısı için const kullanıyoruz
    const tumDiller = kSupportedLocales;

    // DropdownButtonFormField için initialValue kullan
    final Locale initial = tumDiller.any((l) => l.languageCode == _secili.languageCode)
        ? tumDiller.firstWhere((l) => l.languageCode == _secili.languageCode)
        : tumDiller.first;

    return Scaffold(
      appBar: AppBar(title: const Text('Dil Seçimi')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<Locale>(
              initialValue: initial,
              items: tumDiller.map((l) {
                final label = _labelFor(l);
                return DropdownMenuItem(
                  value: l,
                  child: Text(label),
                );
              }).toList(),
              onChanged: (val) {
                if (val == null) return;
                setState(() => _secili = val);
              },
              decoration: const InputDecoration(
                labelText: 'Dil',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  // use_build_context_synchronously uyarısını önlemek için
                  // await'ten önce gerekli referansları alıyoruz.
                  final navigator = Navigator.of(context);
                  final app = EduPlasApp.of(context);

                  await app?.setLocale(_secili);

                  // Burada context kullanmıyoruz; önceden aldığımız navigator ile pop ediyoruz.
                  navigator.pop();
                },
                child: const Text('Kaydet'),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Seçtiğiniz dil uygulama geneline uygulanır ve kaydedilir.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  String _labelFor(Locale l) {
    switch (l.languageCode) {
      case 'tr':
        return 'Türkçe';
      case 'en':
        return 'English';
      case 'ar':
        return 'العربية';
      case 'de':
        return 'Deutsch';
      case 'fr':
        return 'Français';
      case 'es':
        return 'Español';
      case 'pt':
        return 'Português';
      case 'ru':
        return 'Русский';
      case 'zh':
        return '中文';
      case 'ja':
        return '日本語';
      case 'ko':
        return '한국어';
      default:
        return l.languageCode.toUpperCase();
    }
  }
}


